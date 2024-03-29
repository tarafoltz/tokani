# == Schema Information
#
# Table name: addresses
#
#  id               :bigint           not null, primary key
#  address_type     :integer
#  addressable_type :string           not null
#  city             :string
#  country          :string
#  line1            :string
#  line2            :string
#  postal_code      :string
#  state            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  addressable_id   :uuid             not null
#
class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  # validates :address_type, :line1, :city, :postal_code, :country, presence: true
  validates :address_type, :state, :line1, :city, :postal_code, presence: true

  enum address_type: [:billing, :shipping, :physical]

  after_commit -> { addressable.pay_customers.each { |payment_processor| payment_processor.update_customer! } }

  def to_stripe
    {
      city: city,
      country: country,
      line1: line1,
      line2: line2,
      postal_code: postal_code,
      state: state
    }
  end
end
