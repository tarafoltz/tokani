# == Schema Information
#
# Table name: sites
#
#  id            :uuid             not null, primary key
#  active        :boolean          default(TRUE)
#  address       :string
#  city          :string
#  contact_name  :string
#  contact_phone :string
#  email         :string
#  name          :string
#  notes         :text
#  state         :string
#  zip_code      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid
#  backport_id   :bigint
#  customer_id   :uuid             not null
#
# Indexes
#
#  index_sites_on_account_id   (account_id)
#  index_sites_on_backport_id  (backport_id)
#  index_sites_on_customer_id  (customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
require "test_helper"

class SiteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
