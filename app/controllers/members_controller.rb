class MembersController < ApplicationController
  before_action :set_member, only: %i[show edit update destroy toggle_active]

  def index
    @members = policy_scope(Member)
    @members = filter_members(@members)
    @members = search_members(@members)
    @members = @members.order(:name).page(params[:page]).per(20)
    authorize Member
  end

  def show
    authorize @member
    @recent_assignments = @member.assignments.includes(:event, :role)
                                 .order("events.date DESC").limit(10)
    @attendance_records = @member.attendance_records.includes(:event)
                                 .order("events.date DESC").limit(10)
  end

  def new
    @member = Member.new(parish_id: Current.parish_id)
    authorize @member
  end

  def create
    @member = Member.new(member_params)
    @member.parish_id = Current.parish_id
    authorize @member

    if @member.save
      redirect_to member_path(@member), notice: "봉사자가 등록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @member
  end

  def update
    authorize @member
    if @member.update(member_params)
      redirect_to member_path(@member), notice: "봉사자 정보가 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @member
    if @member.destroy
      redirect_to members_path, notice: "봉사자 '#{@member.name}'이(가) 삭제되었습니다."
    else
      error_msg = @member.errors.full_messages.join(", ")
      redirect_to member_path(@member), alert: "삭제할 수 없습니다: #{error_msg}"
    end
  end

  def toggle_active
    authorize @member, :destroy?
    @member.update!(active: !@member.active)
    status = @member.active? ? "활성화" : "비활성화"
    redirect_to member_path(@member), notice: "봉사자가 #{status}되었습니다."
  end

  def bulk_new
    authorize Member, :bulk_create?
  end

  def bulk_create
    authorize Member, :bulk_create?

    unless params[:file].present?
      redirect_to bulk_new_members_path, alert: "CSV 파일을 선택해주세요."
      return
    end

    service = MemberBulkImportService.new(params[:file], Current.user.parish)
    @results = service.import!

    if @results[:errors].empty? && @results[:success] > 0
      redirect_to members_path, notice: "#{@results[:success]}명의 봉사자가 등록되었습니다."
    else
      render :bulk_new, status: :unprocessable_entity
    end
  end

  def sample_csv
    authorize Member, :bulk_create?
    csv_data = MemberBulkImportService.sample_csv
    send_data csv_data, filename: "봉사자_일괄등록_양식.csv", type: "text/csv; charset=utf-8"
  end

  private

  def set_member
    @member = Member.find(params[:id])
  end

  def member_params
    params.require(:member).permit(
      :name, :baptismal_name, :phone, :email, :birth_date,
      :gender, :district, :group_name, :baptized, :confirmed,
      :notes, :user_id
    )
  end

  def search_members(scope)
    return scope if params[:q].blank?
    query = "%#{params[:q]}%"
    scope.where("name LIKE :q OR baptismal_name LIKE :q OR district LIKE :q", q: query)
  end

  def filter_members(scope)
    scope = scope.active if params[:active] == "true"
    scope = scope.inactive if params[:active] == "false"
    scope = scope.baptized if params[:baptized] == "true"
    scope = scope.confirmed if params[:confirmed] == "true"
    scope = scope.by_district(params[:district]) if params[:district].present?
    scope
  end
end
