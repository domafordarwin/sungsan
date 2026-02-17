class DashboardController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      set_current_attributes
      load_dashboard_data
      render :index
    else
      load_landing_data
      render :landing, layout: "landing"
    end
  end

  private

  def load_dashboard_data
    if Current.user.admin? || Current.user.operator?
      @this_week_events = Event.this_week.ordered.limit(5)
      @active_members_count = Member.active.count
      @pending_assignments_count = Assignment.pending.joins(:event)
                                    .where("events.date >= ?", Date.current).count
      @upcoming_events_count = Event.upcoming.count
      @shortage_roles = calculate_shortage_roles
    end

    @recent_news = safe_query { NewsArticle.recent.limit(3) }
    @recent_posts = safe_query { Post.recent.includes(:author).limit(3) }
    @recent_albums = safe_query { PhotoAlbum.recent.includes(:author, :photos).limit(3) }
  end

  def load_landing_data
    @upcoming_events = safe_query { Event.unscoped.upcoming.includes(:event_type).limit(6) }
    @active_surveys = safe_query { Survey.unscoped.active.ordered.limit(3) }
    @recent_albums = safe_query { PhotoAlbum.unscoped.recent.includes(:photos).limit(4) }
  end

  def safe_query
    yield
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound
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
