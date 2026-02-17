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
  u.sample_data = true
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
    r.sample_data = true
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
    et.sample_data = true
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
    q.sample_data = true
  end
end

# 7. 운영자 계정
operator = User.find_or_create_by!(email_address: "operator@sungsan.org") do |u|
  u.parish = parish
  u.name = "운영자"
  u.password = "password123"
  u.role = "operator"
  u.sample_data = true
end

# 8. 테스트 봉사자
members = 10.times.map do |i|
  Member.find_or_create_by!(parish: parish, name: "봉사자#{i + 1}") do |m|
    m.phone = "010-#{rand(1000..9999)}-#{rand(1000..9999)}"
    m.baptismal_name = ["베드로", "바오로", "요한", "마리아", "안나", "요셉", "프란치스코", "데레사", "아녜스", "루치아"][i]
    m.district = "#{rand(1..10)}구역"
    m.baptized = true
    m.confirmed = i < 7
    m.active = true
    m.sample_data = true
  end
end

# 9. 봉사자 역할 배정 (member_roles)
members.each_with_index do |member, i|
  # 봉사자마다 1~3개의 역할 랜덤 배정 (재현 가능하도록 인덱스 기반)
  assigned_roles = roles.select.with_index { |_, ri| (i + ri) % 3 == 0 || ri == i % roles.size }
  assigned_roles.first(2).each do |role|
    MemberRole.find_or_create_by!(member: member, role: role)
  end
end

# 10. 멤버 유저 (봉사자1에 연결)
member_user = User.find_or_create_by!(email_address: "member@sungsan.org") do |u|
  u.parish = parish
  u.name = "봉사자1"
  u.password = "password123"
  u.role = "member"
  u.sample_data = true
end
members.first.update!(user: member_user) unless members.first.user_id

# 11. 샘플 이벤트 (다음 4주 주일미사)
if Event.count == 0
  next_sunday = Date.current.beginning_of_week + 6.days
  next_sunday += 7.days if next_sunday <= Date.current
  4.times do |week|
    date = next_sunday + (week * 7).days
    Event.create!(
      parish: parish,
      event_type: sunday_3rd,
      date: date,
      start_time: "11:00",
      recurring_group_id: SecureRandom.uuid,
      sample_data: true
    )
  end
end

# 12. 샘플 뉴스 기사
news_data = [
  {
    title: "제주교구 사순시기 특별 미사 안내",
    summary: "제주교구에서 사순시기를 맞아 특별 미사를 봉헌합니다. 교구 내 모든 성당에서 참여 가능합니다.",
    source_name: "diocese",
    source_url: "https://www.jejucatholic.org/news/1",
    published_at: 2.days.ago
  },
  {
    title: "가톨릭 청년 봉사단 모집",
    summary: "가톨릭 청년 봉사단에서 새로운 단원을 모집합니다. 관심 있는 청년들의 많은 참여 바랍니다.",
    source_name: "catholic_news",
    source_url: "https://www.catholicnews.co.kr/news/1",
    published_at: 3.days.ago
  },
  {
    title: "성산포 성당 부활절 행사 준비",
    summary: "성산포 성당에서 부활절 행사를 준비하고 있습니다. 봉사자 여러분의 적극적인 참여를 부탁드립니다.",
    source_name: "naver",
    source_url: "https://news.naver.com/article/1",
    published_at: 1.day.ago
  },
]
news_data.each do |attrs|
  ext_id = Digest::MD5.hexdigest(attrs[:source_url])
  NewsArticle.find_or_create_by!(external_id: ext_id) do |n|
    n.parish = parish
    n.title = attrs[:title]
    n.summary = attrs[:summary]
    n.source_name = attrs[:source_name]
    n.source_url = attrs[:source_url]
    n.published_at = attrs[:published_at]
    n.sample_data = true
  end
end

# 13. 샘플 게시글 + 댓글
posts_data = [
  {
    title: "이번 주일 미사 후 다과 나눔 안내",
    body: "이번 주일 3차 미사 후에 성당 마당에서 다과를 나눌 예정입니다.\n\n준비물은 따로 없으니 편하게 오세요!\n봉사자 가족 여러분 모두 환영합니다.",
    pinned: true
  },
  {
    title: "복사 교육 후기",
    body: "지난 토요일 복사 교육에 참석했습니다.\n새로운 전례 순서를 배웠는데 정말 유익했어요.\n다음에도 꼭 참석하려고 합니다!",
    pinned: false
  },
  {
    title: "성당 꽃꽂이 봉사 함께하실 분",
    body: "매주 토요일 오후 2시에 성당 꽃꽂이 봉사를 하고 있습니다.\n관심 있으신 분은 댓글 남겨주세요!",
    pinned: false
  },
]
posts_data.each_with_index do |attrs, i|
  post = Post.find_or_create_by!(parish: parish, title: attrs[:title]) do |p|
    p.author = admin
    p.body = attrs[:body]
    p.pinned = attrs[:pinned]
    p.sample_data = true
  end

  # 샘플 댓글 (첫 번째, 두 번째 게시글에만)
  if i < 2 && post.comments.count == 0
    Comment.create!(
      post: post,
      author: operator,
      body: "좋은 소식 감사합니다! 참석하겠습니다."
    )
    Comment.create!(
      post: post,
      author: member_user,
      body: "저도 참여하고 싶습니다!"
    )
  end
end

puts "Seeding completed!"
puts "  Admin: admin@sungsan.org / password123"
puts "  Operator: operator@sungsan.org / password123"
puts "  Member: member@sungsan.org / password123"
puts ""
puts "  * 모든 예시 데이터에 sample_data=true 표시됨"
puts "  * 일괄 삭제: rails db:purge_sample_data"
puts "  * 현황 확인: rails db:sample_data_status"
