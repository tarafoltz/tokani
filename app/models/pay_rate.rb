# == Schema Information
#
# Table name: pay_rates
#
#  id                   :bigint           not null, primary key
#  after_hours_overage  :decimal(8, 2)
#  cancel_rate          :decimal(8, 2)
#  default_rate         :boolean          default(FALSE)
#  hourly_pay_rate      :decimal(8, 2)
#  in_person            :boolean          default(FALSE)
#  is_active            :boolean          default(TRUE)
#  minimum_time_charged :integer
#  name                 :string
#  phone                :boolean          default(FALSE)
#  rush_overage         :decimal(8, 2)
#  video                :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :uuid
#
class PayRate < ApplicationRecord
  # Broadcast changes in realtime with Hotwire
  after_create_commit -> { broadcast_prepend_later_to :pay_rates, partial: "pay_rates/index", locals: {pay_rate: self} }
  after_update_commit -> { broadcast_replace_later_to self }
  after_destroy_commit -> { broadcast_remove_to :pay_rates, target: dom_id(self, :index) }

  belongs_to :account

  has_many :pay_rate_languages, dependent: :destroy
  has_many :languages, through: :pay_rate_languages

  has_many :pay_rate_interpreters, dependent: :destroy
  has_many :interpreters, through: :pay_rate_interpreters, validate: false, class_name: "User", foreign_key: :interpreter_id

  scope :active, -> { where(is_active: true) }

  validate :check_default_or_language_rate
  validate :cannot_deactivate_last_active_rate, on: :update
  validates :name, presence: true
  validate :must_select_at_least_one_modality

  # has_many :accounts, through: :pay_rate_customers, validate: false, class_name: "Account", foreign_key: :account_id

  def modality_list
    list = []
    list << "In Person" if in_person
    list << "Phone" if phone
    list << "Video" if video
    list.join(", ")
  end

  def language_list
    languages.map(&:name).sort.join(", ")
  end

  def interpreter_list
    interpreters.map { |int| [int.first_name, int.last_name].join(" ") }.sort.join(", ")
  end

  def is_default?
    default_rate
  end

  private

  def cannot_deactivate_last_active_rate
    return if is_active

    default_rate = account.pay_rates.where.not(id: id)
      .where(is_active: true)
      .where(default_rate: true)

    if default_rate.blank?
      errors.add(:base, "Cannot deactive the only default pay rate")
      return false
    end
    true
  end

  def check_default_or_language_rate
    if language_ids.present? && !default_rate == false
      errors.add(:base, "Cannot have default and language specific rate")
      return false
    end
    true
  end

  def must_select_at_least_one_modality
    return if modality_list.present?

    errors.add(:base, "Must select at least one modality")
    false
  end
end
