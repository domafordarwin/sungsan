class DashboardController < ApplicationController
  def index
    if Current.user.admin? || Current.user.operator?
      @this_week_events = Event.this_week.ordered.limit(5)
      @active_members_count = Member.active.count
      @pending_assignments_count = Assignment.pending.joins(:event)
                                    .where("events.date >= ?", Date.current).count
      @upcoming_events_count = Event.upcoming.count

      # 인력 부족 경고
      @shortage_roles = calculate_shortage_roles
    end

    # 모든 사용자에게 표시 (테이블 미존재 시 빈 배열로 처리)
    @recent_news = safe_query { NewsArticle.recent.limit(3) }
    @recent_posts = safe_query { Post.recent.includes(:author).limit(3) }
    @recent_albums = safe_query { PhotoAlbum.recent.includes(:author, :photos).limit(3) }
  end

  private

  def safe_query
    yield
  rescue ActiveRecord::StatementInvalid
    []
  end

  def calculate_shortage_roles
    shortages = []
    Event.upcoming.limit(5).includes(event_type: { event_role_requirements: :role }).each do |event|
      event.event_type.event_role_requirements.each do |req|
        assigned = event.assignments.where(role_id: req.role_id)
                        .where.not(status: "canceled").count
        if assigned < req.required_count
          shortages << {
            event: event,
            role: req.role,
            required: req.required_count,
            assigned: assigned
          }
        end
      end
    end
    shortages.first(5)
  end
end
