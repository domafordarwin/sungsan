class AssignmentRecommender
  def initialize(event, role)
    @event = event
    @role = role
  end

  def candidates(limit: 10)
    members = eligible_members
    scored = members.map { |m| [m, score(m)] }
    scored.sort_by { |_, s| -s }.first(limit).map { |m, s| { member: m, score: s } }
  end

  private

  def eligible_members
    members = Member.active
    members = members.baptized if @role.requires_baptism
    members = members.confirmed if @role.requires_confirmation
    members = members.where.not(id: already_assigned_ids)
    members = members.where.not(id: blackout_member_ids) if blackout_member_ids.any?
    members
  end

  def already_assigned_ids
    @event.assignments.where.not(status: "canceled").pluck(:member_id)
  end

  def blackout_member_ids
    BlackoutPeriod.active_on(@event.date).pluck(:member_id)
  end

  def score(member)
    s = 100
    recent_count = member.assignments
      .where(created_at: 30.days.ago..)
      .where.not(status: "canceled")
      .count
    s -= (recent_count * 10)
    if member.availability_rules.exists?(day_of_week: @event.date.wday)
      s += 20
    end
    [s, 0].max
  end
end
