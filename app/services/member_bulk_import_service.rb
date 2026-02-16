require "csv"

class MemberBulkImportService
  EXPECTED_HEADERS = %w[이름 세례명 연락처 이메일 구역 성별 세례여부 견진여부].freeze

  attr_reader :results

  def initialize(file, parish)
    @file = file
    @parish = parish
    @results = { success: 0, failed: 0, errors: [], created_members: [] }
  end

  def import!
    content = @file.read.force_encoding("UTF-8")
    # BOM 제거
    content = content.sub("\xEF\xBB\xBF", "")

    csv = CSV.parse(content, headers: true, liberal_parsing: true)

    validate_headers!(csv.headers)
    return @results if @results[:errors].any?

    csv.each_with_index do |row, index|
      row_num = index + 2 # 헤더 제외, 1-based
      import_row(row, row_num)
    end

    @results
  rescue CSV::MalformedCSVError => e
    @results[:errors] << "CSV 파일 형식이 올바르지 않습니다: #{e.message}"
    @results
  rescue StandardError => e
    @results[:errors] << "파일 처리 중 오류가 발생했습니다: #{e.message}"
    @results
  end

  def self.sample_csv
    CSV.generate do |csv|
      csv << EXPECTED_HEADERS
      csv << ["홍길동", "베드로", "010-1234-5678", "hong@example.com", "1구역", "남", "예", "예"]
      csv << ["김영희", "마리아", "010-9876-5432", "kim@example.com", "2구역", "여", "예", "아니오"]
    end
  end

  private

  def validate_headers!(headers)
    cleaned = (headers || []).map { |h| h&.strip }
    missing = EXPECTED_HEADERS - cleaned
    if missing.any?
      @results[:errors] << "필수 컬럼이 누락되었습니다: #{missing.join(', ')}. 필요한 컬럼: #{EXPECTED_HEADERS.join(', ')}"
    end
  end

  def import_row(row, row_num)
    name = row["이름"]&.strip
    if name.blank?
      @results[:errors] << "#{row_num}행: 이름이 비어있습니다."
      @results[:failed] += 1
      return
    end

    member = Member.new(
      parish: @parish,
      name: name,
      baptismal_name: row["세례명"]&.strip,
      phone: row["연락처"]&.strip,
      email: row["이메일"]&.strip,
      district: row["구역"]&.strip,
      gender: parse_gender(row["성별"]&.strip),
      baptized: parse_boolean(row["세례여부"]&.strip),
      confirmed: parse_boolean(row["견진여부"]&.strip),
      active: true
    )

    if member.save
      @results[:success] += 1
      @results[:created_members] << member
    else
      @results[:failed] += 1
      @results[:errors] << "#{row_num}행 (#{name}): #{member.errors.full_messages.join(', ')}"
    end
  end

  def parse_gender(value)
    case value
    when "남", "남성", "M", "male" then "male"
    when "여", "여성", "F", "female" then "female"
    else nil
    end
  end

  def parse_boolean(value)
    %w[예 Y y yes true 1 O o].include?(value)
  end
end
