class InterpretersController < ApplicationController
  include CurrentHelper

  before_action :authenticate_user!
  # Uncomment to enforce Pundit authorization
  before_action :verify_authorized, except: [:search, :search_assigned_int]
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :verify_interpreter_detail, except: [:index, :show, :new, :edit, :update, :destroy, :search, :search_assigned_int]

  before_action :set_interpreter, only: [:show, :edit, :update, :destroy, :availabilities, :update_timezone]
  before_action :set_appointment, only: [:my_public_details, :my_scheduled_details, :my_assigned_details, :claim_public,
    :decline_offered, :accept_offered, :cancel_coverage, :time_finish, :appointment_details, :edit_time_finish]

  # GET /interpreters
  def index
    @pagy, @interpreters = pagy(User.where(id: current_account.account_users.interpreter.pluck(:user_id)).sort_by_params(params[:sort], sort_direction))

    # Uncomment to authorize with Pundit
    # authorize @interpreters
  end

  def search_assigned_int
    name_query = params[:q]
    name_query = "%#{name_query}%"

    # language_id = params[:language_id]
    # modality = params[:modality]

    # if name_query.blank? || language_id.blank?
    if name_query.blank?
      @interpreters = []
    else
      # @interpreters = Interpreter.joins(:interpreter_languages).where('interpreter_languages.language_id = :language_id', {language_id: language_id})
      if agency_logged_in?
        @interpreters = current_account.interpreters
      else
        agency_id = AgencyCustomer.find_by(customer_id: current_account.id).agency_id
        @interpreters = Account.find(agency_id).interpreters
      end
      @interpreters = @interpreters.where("last_name ilike ? or first_name ilike ?", name_query, name_query)
    end

    respond_to do |format|
      format.html { render partial: "search_results" }
    end
  end

  def search
    name_query = params[:q]
    name_query = "%#{name_query}%"

    language_id = params[:language_id]
    # modality = params[:modality]

    if name_query.blank? || language_id.blank?
      @interpreters = []
    else
      # @interpreters = Interpreter.joins(:interpreter_languages).where('interpreter_languages.language_id = :language_id', {language_id: language_id})
      if agency_logged_in?
        @interpreters = current_account.interpreters.joins(:interpreter_languages).where("interpreter_languages.language_id = :language_id", {language_id: language_id})
      else
        agency_id = AgencyCustomer.find_by(customer_id: current_account.id).agency_id
        @interpreters = Account.find(agency_id).interpreters.joins(:interpreter_languages).where("interpreter_languages.language_id = :language_id", {language_id: language_id})
      end
      @interpreters = @interpreters.where("last_name ilike ? or first_name ilike ?", name_query, name_query)
    end

    respond_to do |format|
      format.html { render partial: "search_results" }
    end
  end

  def new
    @interpreter = User.new
    @interpreter.build_interpreter_detail
  end

  def show
    @checklist_items = @interpreter.checklist_items.includes(:checklist_type).with_attached_document.order("checklist_types.name ASC")
  end

  def edit
    setup_edit_form_vars
  end

  def create
    @interpreter = User.new(interpreter_params)
    @interpreter.terms_of_service = true
    @interpreter.password = SecureRandom.alphanumeric
    @interpreter.skip_default_account = true

    respond_to do |format|
      if @interpreter.save
        AccountUser.create!(account_id: current_account.id, user_id: @interpreter.id, roles: {"interpreter" => true})
        @interpreter.send_interpreter_creation_mailer(current_account)
        format.html { redirect_to interpreter_path(@interpreter), notice: "Interpreter was successfully created." }
        format.json { render :show, status: :created, location: @interpreter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @interpreter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /interpreters/1 or /interpreters/1.json
  def update
    respond_to do |format|
      if @interpreter.update(interpreter_params)
        notice = if @interpreter.unconfirmed_email_updated
          "Interpreter was successfully updated.<br> A confirmation email was sent to #{@interpreter.unconfirmed_email}."
        else
          "Interpreter was successfully updated."
        end
        format.html { redirect_to interpreter_path(@interpreter), notice: notice }
        format.json { render :show, status: :ok, location: @interpreter }
      else
        setup_edit_form_vars
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @interpreter.errors, status: :unprocessable_entity }
      end
    end
  end

  def dashboard
    @service = InterpreterAppointmentsService.new(current_user, appointment_query_params, current_account)
    @appointments = @service.fetch_appointments
    @appointments = @service.restrict_to_assigned_or_viewable(@appointments)
    @created_appointments_count = @appointments.where(current_status: "offered").or(@appointments.where(current_status: "opened")).count
    @appointments_scheduled_count = @appointments.where(current_status: "scheduled").count
    @appointments_completed_count = @appointments.where(current_status: "finished").count

    @pagy, @appointments = pagy(@appointments.sort_by_params(params[:sort], sort_direction))
  end

  def public
    @title = "Public"
    @status = "opened"
    @service = InterpreterAppointmentsService.new(current_user, {status: @status, display_range: "today"})
    @appointments = @service.fetch_appointments
  end

  def my_public_details
  end

  def my_scheduled
    @title = "My Scheduled"
    @status = "scheduled"
    @service = InterpreterAppointmentsService.new(current_user, {status: @status, display_range: "today"})
    @appointments = @service.fetch_appointments
  end

  def my_scheduled_details
    setup_form_vars
  end

  def my_assigned
    @title = "My Offered"
    @status = "offered"
    @service = InterpreterAppointmentsService.new(current_user, {status: @status, display_range: "today"})
    @appointments = @service.fetch_appointments
  end

  def my_assigned_details
  end

  def claim_public
    @appointment.update(interpreter_id: current_user.id)
    AppointmentStatus.create!(appointment: @appointment, name: AppointmentStatus.names["scheduled"], user: current_user)

    redirect_to(appointment_details_interpreter_path(@appointment), alert: "Assignment successfully accepted.")
  end

  def decline_offered
    @requested_interpreter = @appointment.requested_interpreters.where(user_id: current_user.id)
    @requested_interpreter.update(rejected: true, status: RequestedInterpreter.statuses["rejected"])
    @unrejected_requests = @appointment.requested_interpreters.where(rejected: false)
    if @unrejected_requests.blank?
      # There are no unrejected interpreter requests left; we need to clear them out & reset the appointment
      @appointment.requested_interpreters.destroy_all
      AppointmentStatus.create!(appointment: @appointment, name: AppointmentStatus.names["created"], user: current_user)
    end

    redirect_to(interpreter_dashboard_path, alert: "Assignment successfully declined.")
  end

  def accept_offered
    @appointment.update(interpreter_id: current_user.id)
    AppointmentStatus.create!(appointment: @appointment, name: AppointmentStatus.names["scheduled"], user: current_user)
    redirect_to(interpreter_dashboard_path, alert: "Assignment successfully accepted.")
  end

  def cancel_coverage
    @appointment.update(interpreter_id: nil)
    # Make sure we kick the Appointment back into the correct status, depending on visibility status
    if @appointment.visibility_status == "opened"
      AppointmentStatus.create!(appointment: @appointment, name: AppointmentStatus.names["opened"], user: current_user)
      NotificationsService.deliver_interpreter_cancelled_notifications(account: current_account, interpreter: current_user, appointment: @appointment)
    elsif @appointment.visibility_status == "offered"
      AppointmentStatus.create!(appointment: @appointment, name: AppointmentStatus.names["offered"], user: current_user)
    else
      raise "Invalid visibility_status for Appointment #{@appointment.id}: #{@appointment.visibility_status}"
    end
    redirect_to(interpreter_dashboard_path, alert: "You have been unassigned from the appointment.")
  end

  def time_finish
    @appointment.combine_finish_date_and_time(appointment_params[:submitted_finish_date], appointment_params[:submitted_finish_time], current_user)

    if @appointment.finish_time < @appointment.start_time
      setup_form_vars
      flash[:alert] = "There was a problem time finishing the appointment: Finish time must be later than the start time."
      return render :my_scheduled_details
    end

    if @appointment.update(appointment_params)
      AppointmentStatus.create!(appointment: @appointment, name: AppointmentStatus.names["finished"], user: current_user)
      redirect_to(interpreter_dashboard_path, notice: "Appointment time finished.")
    else
      setup_form_vars
      errors = @appointment.errors.full_messages.join("; ")
      flash[:alert] = "There was a problem time finishing the appointment: #{errors}"
      render :my_scheduled_details
    end
  end

  def profile
  end

  def profile_notifications_edit
  end

  def profile_personal_edit
  end

  def profile_security_edit
  end

  # Action that views can link to that will redirect appointment to appropriate details page
  def appointment_details
    if @appointment.status == "offered"
      request = @appointment.requested_interpreters.where(rejected: false).where(user_id: current_user.id).first
      if request.present?
        # Appointment is in the Offered status and there is an active request for the interpreter
        redirect_to(my_assigned_details_interpreter_path(@appointment))
      else
        # Perhaps they have already rejected this offer?
        redirect_to(interpreter_dashboard_path, alert: "It appears you have already declined this appointment.")
      end
    elsif (@appointment.status == "scheduled") && (@appointment.interpreter_id == current_user.id)
      redirect_to(my_scheduled_details_interpreter_path(@appointment))
    elsif @appointment.status == "opened"
      redirect_to(my_public_details_interpreter_path(@appointment))
    elsif @appointment.status == "finished"
      redirect_to(my_scheduled_details_interpreter_path(@appointment))
    else
      redirect_to(interpreter_dashboard_path, alert: "Could not find appointment in an offered or scheduled status.")
    end
  end

  def add_availability
    @interpreter = current_user
    @availabilities = @interpreter.availabilities.group_by(&:wday)
    @days = Date::DAYNAMES
  end

  def update_timezone_view
    @interpreter = current_user
  end

  def availability
    @interpreter = current_user
    @availabilities = @interpreter.availabilities
    @days = Date::DAYNAMES
  end

  # This method accepts as part of the URL params an interpreter ID, suitable
  # for someone other than the interpreter (i.e. Requestor) to update the availability.
  def availabilities
    @availabilities = @interpreter.availabilities.group_by(&:wday)
    @days = Date::DAYNAMES
    render :availability
  end

  def update_timezone
    timezone = params[:timezone]
    @interpreter.time_zone = timezone if timezone.present?

    if @interpreter.save
      @interpreter.availabilities.destroy_all
      flash[:timezone_notice] = "You successfully updated your timezone to #{timezone}."
    else
      flash[:timezone_notice] = "Something went wrong updating your timezone: #{@interpreter.errors.full_messages.join("; ")}"
    end

    render turbo_stream: turbo_stream.replace("availability", template: "interpreters/availability")
    # redirect_to interpreters_availability_path
  end

  def appointments
    @service = InterpreterAppointmentsService.new(current_user, appointment_query_params, current_account)
    @appointments = @service.fetch_appointments
    @appointments = @service.restrict_to_assigned_or_viewable(@appointments)
    @pagy, @appointments = pagy(@appointments.sort_by_params(params[:sort], sort_direction))

    @statuses = ["all", "scheduled", "finished", "opened"]
    @modalities = ["in_person", "video", "phone"]
    @sort_by_filters = ["date"]
  end

  def filter_appointments
  end

  def income
    search_params = appointment_query_params
    if search_params.blank? || search_params[:status].blank? || search_params[:status] == "all"
      search_params[:status] = "processed"
    end
    @service = InterpreterAppointmentsService.new(current_user, search_params, current_account)
    @appointments = @service.fetch_appointments
    @pagy, @appointments = pagy(@appointments)

    @statuses = ["all", "finished", "verified", "exported"]
    @modalities = ["in_person", "video", "phone"]
    @sort_by_filters = ["date"]
    @show_payment_amount = true
  end

  def edit_time_finish
    setup_form_vars
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def verify_authorized
    puts "\n\ncustomer_logged_in? : #{customer_logged_in?}\n\n"
    raise Pundit::NotAuthorizedError if customer_logged_in?
  end

  def verify_interpreter_detail
    return if current_user.interpreter_detail_filled_out?

    redirect_to new_interpreter_detail_path
  end

  def set_interpreter
    int = current_account.account_users.interpreter.find_by(user_id: params[:id])
    int_id = int.user_id
    @interpreter = User.find_by(id: int_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to interpreters_path
  end

  def set_appointment
    @appointment = current_account.appointments.find_by(id: params[:id])
    if @appointment.nil?
      redirect_to(interpreter_dashboard_path, alert: "Appointment not found.")
    end
  end

  def setup_edit_form_vars
    @languages_json = current_account.languages.pluck(:id, :name).map { |u| {value: u[0], text: u[1]} }.to_json
    @interpreter_languages_json = @interpreter.languages.pluck(:id, :name).map { |u| {value: u[0], text: u[1]} }.to_json
  end

  def setup_form_vars
    @docs_list = @appointment.documents.map { |doc| {name: doc.filename.to_s, size: doc.byte_size, url: url_for(doc), signed_id: doc.signed_id} }
    @docs_list_json = @docs_list.to_json
  end

  # Only allow a list of trusted parameters through.
  def interpreter_params
    params.require(:user).permit(
      :email,
      :password,
      :first_name,
      :last_name,
      :terms_of_service,
      language_ids: [],
      interpreter_detail_attributes: [
        :id,
        :interpreter_id,
        :gender,
        :interpreter_type,
        :primary_phone,
        :email,
        :ssn,
        :dob,
        :start_date,
        :drivers_license,
        :emergency_contact_name,
        :emergency_contact_phone,
        :address,
        :city,
        :state,
        :zip,
        :time_zone
      ]
    )
  end

  def appointment_params
    params.require(:appointment).permit(
      :submitted_finish_date,
      :submitted_finish_time,
      :billing_notes,
      documents: []
    )
  end

  def appointment_query_params
    params.permit(
      :status, :display_range, :start_date,
      :end_date, :modality_in_person, :modality_phone,
      :modality_video, :search_query, sort_by: [:date, :customer]
    )
  end
end
