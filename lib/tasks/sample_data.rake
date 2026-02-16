namespace :db do
  desc "샘플 데이터 일괄 삭제 (sample_data=true인 레코드 모두 제거)"
  task purge_sample_data: :environment do
    puts "=== 샘플 데이터 일괄 삭제 시작 ==="
    puts ""

    total = 0

    # 의존관계 역순으로 삭제 (자식 → 부모)
    # 1. Events 먼저 삭제 (assignments, attendance_records cascade)
    count = Event.unscoped.where(sample_data: true).destroy_all.size
    puts "  Events:         #{count}건 삭제"
    total += count

    # 2. Members 삭제 (availability_rules, blackout_periods, member_qualifications cascade)
    count = Member.unscoped.where(sample_data: true).destroy_all.size
    puts "  Members:        #{count}건 삭제"
    total += count

    # 3. Users 삭제 (sessions cascade)
    count = User.unscoped.where(sample_data: true).destroy_all.size
    puts "  Users:          #{count}건 삭제"
    total += count

    # 4. Qualifications 삭제 (member_qualifications는 이미 2에서 삭제됨)
    count = Qualification.unscoped.where(sample_data: true).destroy_all.size
    puts "  Qualifications: #{count}건 삭제"
    total += count

    # 5. EventTypes 삭제 (event_role_requirements cascade, events는 1에서 삭제됨)
    count = EventType.unscoped.where(sample_data: true).destroy_all.size
    puts "  EventTypes:     #{count}건 삭제"
    total += count

    # 6. Roles 삭제 (event_role_requirements cascade)
    count = Role.unscoped.where(sample_data: true).destroy_all.size
    puts "  Roles:          #{count}건 삭제"
    total += count

    puts ""
    puts "=== 총 #{total}건 삭제 완료 ==="
  end

  desc "샘플 데이터 현황 확인"
  task sample_data_status: :environment do
    puts "=== 샘플 데이터 현황 ==="
    puts ""

    models = [
      ["Users",          User],
      ["Members",        Member],
      ["Events",         Event],
      ["Roles",          Role],
      ["EventTypes",     EventType],
      ["Qualifications", Qualification],
    ]

    models.each do |label, model|
      sample_count = model.unscoped.where(sample_data: true).count
      total_count  = model.unscoped.count
      real_count   = total_count - sample_count

      status = sample_count > 0 ? "  <-- 삭제 대상" : ""
      puts "  %-16s 전체: %3d | 실제: %3d | 샘플: %3d%s" % [label, total_count, real_count, sample_count, status]
    end

    puts ""
    puts "  삭제 명령: rails db:purge_sample_data"
  end
end
