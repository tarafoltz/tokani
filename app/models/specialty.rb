# == Schema Information
#
# Table name: specialties
#
#  id           :bigint           not null, primary key
#  display_code :string
#  is_active    :boolean
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Specialty < ApplicationRecord
  # Broadcast changes in realtime with Hotwire
  after_create_commit -> { broadcast_prepend_later_to :specialties, partial: "specialties/index", locals: {specialty: self} }
  after_update_commit -> { broadcast_replace_later_to self }
  after_destroy_commit -> { broadcast_remove_to :specialties, target: dom_id(self, :index) }

  has_many :interpreter_specialties, dependent: :destroy
  has_many :interpreters, through: :interpreter_specialties, foreign_key: :interpreter_id
  has_many :appointment_specialties, dependent: :destroy
  has_many :appointments, through: :appointment_specialties
end
