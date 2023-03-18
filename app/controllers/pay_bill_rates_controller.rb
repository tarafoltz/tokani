class PayBillRatesController < ApplicationController
  include CurrentHelper

  before_action :set_pay_bill_rate, only: [:show, :edit, :update, :destroy]

  # Uncomment to enforce Pundit authorization
  # after_action :verify_authorized
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # GET /pay_bill_rates
  def index
    @pagy, @pay_bill_rates = pagy(current_account.pay_bill_rates.sort_by_params(params[:sort], sort_direction))

    # Uncomment to authorize with Pundit
    # authorize @pay_bill_rates
  end

  # GET /pay_bill_rates/1 or /pay_bill_rates/1.json
  def show
    @customers = current_account.customers

    # TODO - We eventually need to port over this logic that restricts the Interpreters by language.

    # pbr_language_ids = @pay_bill_rate.languages.pluck(:id)
    # pbr_language_ids ||= []

    # if !pbr_language_ids.empty?
    #   interpreter_ids = Interpreter.joins(:interpreter_languages).select(:user_id).where(interpreter_languages: {language_id: pbr_language_ids}).group(:user_id)
    #   @avail_interpreters = Interpreter.where(is_active: true, id: interpreter_ids).order('lname ASC')
    # else
    #   @avail_interpreters = Interpreter.where(is_active: true).order('lname ASC')
    # end
    @avail_interpreters = current_account.account_interpreters
  end

  # GET /pay_bill_rates/new
  def new
    @pay_bill_rate = PayBillRate.new

    @languages = current_account.languages.all.order("name ASC")
    @customers = current_account.customers.order("name ASC")
    @specialties = current_account.specialties.active.order("name ASC")

    # Uncomment to authorize with Pundit
    # authorize @pay_bill_rate
  end

  # GET /pay_bill_rates/1/edit
  def edit
    @languages = current_account.languages.all.order("name ASC")
    @customers = current_account.customers.order("name ASC")
    @specialties = current_account.specialties.active.order("name ASC")
  end

  # POST /pay_bill_rates or /pay_bill_rates.json
  def create
    @pay_bill_rate = PayBillRate.new(pay_bill_rate_params)
    @pay_bill_rate.account_id = current_account.id

    # Uncomment to authorize with Pundit
    # authorize @pay_bill_rate

    respond_to do |format|
      if @pay_bill_rate.save
        format.html { redirect_to @pay_bill_rate, notice: "Pay bill rate was successfully created." }
        format.json { render :show, status: :created, location: @pay_bill_rate }
      else
        setup_form_vars
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pay_bill_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pay_bill_rates/1 or /pay_bill_rates/1.json
  def update
    respond_to do |format|
      if @pay_bill_rate.update(pay_bill_rate_params)
        format.html { redirect_to @pay_bill_rate, notice: "Pay bill rate was successfully updated." }
        format.json { render :show, status: :ok, location: @pay_bill_rate }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pay_bill_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pay_bill_rates/1 or /pay_bill_rates/1.json
  def destroy
    @pay_bill_rate.destroy
    respond_to do |format|
      format.html { redirect_to pay_bill_rates_url, status: :see_other, notice: "Pay bill rate was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def setup_form_vars
    @languages = current_account.languages.all.order("name ASC")
    @selected_language_ids = pay_bill_rate_params[:language_ids] if pay_bill_rate_params[:language_ids]
    @customers = current_account.customers.order("name ASC")
    @specialties = current_account.specialties.active.order("name ASC")
    @pay_bill_rate_params = pay_bill_rate_params
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_pay_bill_rate
    @pay_bill_rate = current_account.pay_bill_rates.find(params[:id])

    # Uncomment to authorize with Pundit
    # authorize @pay_bill_rate
  rescue ActiveRecord::RecordNotFound
    redirect_to pay_bill_rates_path
  end

  # Only allow a list of trusted parameters through.
  def pay_bill_rate_params
    params.require(:pay_bill_rate).permit(:account_id, :name, :is_default, :effective_date, :bill_rate, :pay_rate, :after_hours_bill_rate,
      :after_hours_pay_rate, :rush_bill_rate, :rush_pay_rate, :discount_bill_rate, :discount_pay_rate, :cancel_level_1_bill_rate,
      :cancel_level_1_pay_rate, :cancel_level_2_bill_rate, :cancel_level_2_pay_rate, :mileage_rate, :travel_time_rate, :in_person,
      :phone, :video, :interpreter_types, :is_active, :customer_ids, :account_ids,
      language_ids: [], account_ids: [], site_ids: [], department_ids: [], interpreter_ids: [],
      specialty_ids: [], interpreter_type_ids: [])
  end
end