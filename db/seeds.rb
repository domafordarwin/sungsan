puts "Seeding AltarServe Manager..."

# 1. 기본 본당
parish = Parish.find_or_create_by!(name: "성산성당") do |p|
  p.address = "서울시 마포구 성산동"
  p.phone = "02-123-4567"
end

# 2. 관리자 계정 (Rails 8 빌트인 인증)
admin = User.find_or_create_by!(email_address: "admin@sungsan.org") do |u|
  u.parish = parish
  u.name = "관리자"
  u.password = "password123"
  u.role = "admin"
end

# 3. 역할 정의
roles_data = [
  { name: "독서1", sort_order: 1 },
  { name: "독서2", sort_order: 2 },
  { name: "해설", sort_order: 3 },
  { name: "복사", sort_order: 4, requires_baptism: true },
  { name: "성가", sort_order: 5 },
  { name: "봉헌", sort_order: 6 },
  { name: "제대회", sort_order: 7, requires_confirmation: true },
]
roles = roles_data.map do |attrs|
  Role.find_or_create_by!(parish: parish, name: attrs[:name]) do |r|
    r.assign_attributes(attrs)
  end
end

# 4. 미사 유형
event_types_data = [
  { name: "주일미사(1차)", default_time: "07:00" },
  { name: "주일미사(2차)", default_time: "09:00" },
  { name: "주일미사(3차)", default_time: "11:00" },
  { name: "주일미사(4차)", default_time: "17:00" },
  { name: "평일미사", default_time: "06:30" },
  { name: "토요미사", default_time: "16:00" },
  { name: "대축일미사", default_time: "10:00" },
]
event_types = event_types_data.map do |attrs|
  EventType.find_or_create_by!(parish: parish, name: attrs[:name]) do |et|
    et.assign_attributes(attrs)
  end
end

# 5. 미사유형별 역할 요구사항 (주일미사 3차 예시)
sunday_3rd = event_types.find { |et| et.name == "주일미사(3차)" }
[
  { role: "독서1", count: 1 },
  { role: "독서2", count: 1 },
  { role: "해설", count: 1 },
  { role: "복사", count: 4 },
  { role: "성가", count: 2 },
  { role: "봉헌", count: 2 },
  { role: "제대회", count: 2 },
].each do |req|
  role = roles.find { |r| r.name == req[:role] }
  EventRoleRequirement.find_or_create_by!(event_type: sunday_3rd, role: role) do |err|
    err.required_count = req[:count]
  end
end

# 6. 자격/교육 정의
qualifications_data = [
  { name: "복사 교육", validity_months: 12 },
  { name: "독서 교육", validity_months: nil },
  { name: "안전 교육", validity_months: 12 },
]
qualifications_data.each do |attrs|
  Qualification.find_or_create_by!(parish: parish, name: attrs[:name]) do |q|
    q.assign_attributes(attrs)
  end
end

# 7. 개발용 테스트 봉사자 (development 환경만)
if Rails.env.development?
  10.times do |i|
    Member.find_or_create_by!(parish: parish, name: "봉사자#{i + 1}") do |m|
      m.phone = "010-#{rand(1000..9999)}-#{rand(1000..9999)}"
      m.baptismal_name = ["베드로", "바오로", "요한", "마리아", "안나", "요셉", "프란치스코", "데레사", "아녜스", "루치아"][i]
      m.district = "#{rand(1..10)}구역"
      m.baptized = true
      m.confirmed = i < 7
      m.active = true
    end
  end
end

puts "Seeding completed!"
