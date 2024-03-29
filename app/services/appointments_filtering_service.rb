# A service object for fetching appointments with various filters
class AppointmentsFilteringService
  include ActionController::Helpers
  include Sortable

  def initialize(user, account, params, scope)
    @user = user
    @account = account
    @params = params
    @scope = scope
  end

  attr_accessor :params

  def fetch_appointments
    return filter_by_user_account_type(@scope) if @params.values.blank?

    @scope = filter_by_user_account_type(@scope)
    @scope = filter_by_status(@scope)
    @scope = filter_by_customer(@scope)
    @scope = filter_by_modality(@scope)
    @scope = scope_by_date_range(@scope)
    @scope = filter_by_search_query(@scope)
    @scope
  end

  private

  def filter_by_user_account_type(scope)
    return scope if @user.is_agency_admin?

    customer_id = @user&.requestor_detail&.customer_id
    return scope if customer_id.nil?

    scope.where(customer_id: customer_id)
  end

  def filter_by_status(scope)
    return scope unless @params[:status].present?

    case @params[:status]
    when "all"
      scope
    else
      scope.by_appointment_specific_status(@params[:status])
    end
  end

  def filter_by_customer(scope)
    return scope unless @params[:customer_name].present?

    case @params[:customer_name]
    when "all"
      scope
    else
      scope.by_customer_name(@params[:customer_name])
    end
  end

  def filter_by_modality(scope)
    return scope unless @params[:modality_in_person].present? || @params[:modality_phone].present? || @params[:modality_video].present?

    modalities = []

    if @params[:modality_in_person].present?
      modalities << Appointment.modalities["in_person"]
    end

    if @params[:modality_phone].present?
      modalities << Appointment.modalities["phone"]
    end

    if @params[:modality_video].present?
      modalities << Appointment.modalities["video"]
    end

    scope.where(modality: modalities)
  end

  def order_by_start_time(scope)
    scope.order(start_time: :asc)
  end

  def scope_by_today(scope)
    beginning_of_day = DateTime.now.in_time_zone(@user.time_zone).beginning_of_day
    end_of_day = DateTime.now.in_time_zone(@user.time_zone).end_of_day

    scope_by_range(scope, beginning_of_day, end_of_day)
  end

  def scope_by_tomorrow(scope)
    beginning_of_day = 1.day.from_now.in_time_zone(@user.time_zone).beginning_of_day
    end_of_day = 1.day.from_now.in_time_zone(@user.time_zone).end_of_day

    scope_by_range(scope, beginning_of_day, end_of_day)
  end

  def scope_by_date_range(scope)
    return scope unless @params[:start_date].present? && @params[:end_date].present?
    start_date = Date.parse(@params[:start_date])
    end_date = Date.parse(@params[:end_date])

    beginning_of_day = start_date.noon.in_time_zone(@user.time_zone).beginning_of_day
    end_of_day = end_date.noon.in_time_zone(@user.time_zone).end_of_day

    scope_by_range(scope, beginning_of_day, end_of_day)
  end

  def scope_by_range(scope, start_time, end_time)
    scope.where("appointments.start_time > ?", start_time.utc)
      .where("appointments.start_time < ?", end_time.utc)
  end

  def filter_by_search_query(scope)
    return scope unless @params[:search_query].present?
    query = @params[:search_query]
    query = "%#{query}%"

    scope.includes(:customer, :site, :interpreter)
      .references(:account, :site, :users)
      .where(
        "appointments.ref_number ILIKE ? OR accounts.name ILIKE ? OR sites.name ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ?",
        query, query, query, query, query
      )
  end
end
