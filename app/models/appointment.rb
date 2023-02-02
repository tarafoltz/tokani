# == Schema Information
#
# Table name: appointments
#
#  id                       :bigint           not null, primary key
#  admin_notes              :text
#  billing_notes            :text
#  cancel_reason_code       :integer
#  cancel_type              :integer
#  canceled_by              :integer
#  cancelled_at             :datetime
#  confirmation_date        :datetime
#  confirmation_notes       :text
#  confirmation_phone       :string
#  details                  :text
#  duration                 :integer
#  finish_time              :datetime
#  gender_req               :integer
#  home_health_appointment  :boolean
#  interpreter_type         :integer
#  lock_version             :integer
#  modality                 :integer
#  notes                    :text
#  processed_by_customer    :boolean          default(FALSE)
#  processed_by_interpreter :boolean          default(FALSE)
#  ref_number               :string
#  start_time               :datetime
#  status                   :boolean
#  sub_type                 :integer
#  time_zone                :string
#  total_billed             :decimal(, )
#  total_paid               :decimal(, )
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  agency_id                :uuid
#  customer_id              :uuid
#  interpreter_id           :uuid
#  pay_bill_config_id       :integer
#  pay_bill_rate_id         :integer
#  site_id                  :uuid
#
# Indexes
#
#  index_appointments_on_agency_id       (agency_id)
#  index_appointments_on_customer_id     (customer_id)
#  index_appointments_on_interpreter_id  (interpreter_id)
#
class Appointment < ApplicationRecord
  # Broadcast changes in realtime with Hotwire
  after_create_commit -> { broadcast_prepend_later_to :appointments, partial: "appointments/index", locals: {appointment: self} }
  after_update_commit -> { broadcast_replace_later_to self }
  after_destroy_commit -> { broadcast_remove_to :appointments, target: dom_id(self, :index) }

  has_many :appointment_languages, dependent: :destroy
  has_many :appointment_specialties, dependent: :destroy
  has_many :specialties, through: :appointment_specialties
  has_many :appointment_statuses, dependent: :destroy
  has_many :billing_line_items, dependent: :destroy
  has_many :payment_line_items, dependent: :destroy

  belongs_to :agency, class_name: "Account"
  belongs_to :customer, class_name: "Account", optional: true
  belongs_to :interpreter, class_name: "User", optional: true
  belongs_to :site, optional: true
  belongs_to :pay_bill_rate, optional: true
  belongs_to :pay_bill_config, optional: true

  enum cancel_type: {agency: 0, requestor: 1}

  def status
    appointment_statuses.current.name
  end

  def refnumber
    # Temporary placeholder until this is implemented
    "REFNUMBER"
  end

  def start_time_with_zone
    start_time.in_time_zone(time_zone)
  end

  def end_time_with_zone
    end_time.in_time_zone(time_zone)
  end

  def finish_time_with_zone
    finish_time.in_time_zone(time_zone)
  end

  def associate_rate_via_service
    service = RateDeterminationService.new(self)
    rate = service.determine_rate
    update_column(:pay_bill_rate_id, rate.id) if rate.present?
  end

  def associate_config_via_service
    service = ConfigDeterminationService.new(self)
    config = service.determine_config
    update_column(:pay_bill_config_id, config.id) if config.present?
  end

  def create_line_items_and_save_totals
    return unless pay_bill_rate_id.present? && pay_bill_config_id.present?

    service = RateCalculationService.new(self)

    billing_line_items.destroy_all
    BillingLineItem.persist_from_struct(self, service.billing_line_items)

    payment_line_items.destroy_all
    PaymentLineItem.persist_from_struct(self, service.payment_line_items)

    update_columns(total_billed: service.total_bill,
      total_paid: service.total_pay)
  end

  def calculated_appointment_duration_in_hours
    return nil unless start_time.present? && finish_time.present?

    TimeDifference.between(start_time, finish_time).in_hours
  end

  def starts_on_weekday?
    return nil if start_time.blank?

    # Use wday to determine start day. 0-6, Sunday is 0
    [1, 2, 3, 4, 5].include?(start_time_with_zone.wday)
  end

  def billing_types
    billing_line_items.map { |li| li.type_key.titleize }.join(" - ")
  end

  def payment_types
    payment_line_items.map { |li| li.type_key.titleize }.join(" - ")
  end

  def duration_in_minutes
    (duration / 60.0).round(0)
  end

  def duration_viewable
    "#{duration_in_minutes} minutes"
  end
end
