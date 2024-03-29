require "test_helper"

class Jumpstart::AccountUsersTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:company)
    @admin = users(:one)
    @regular_user = users(:two)
    @agency_admin = account_users(:agency_admin)
    @agency_member = account_users(:agency_member)
    @customer_admin = account_users(:customer_admin)
    @customer_member = account_users(:customer_member)
  end

  class AdminUsers < Jumpstart::AccountUsersTest
    setup do
      sign_in @admin
    end

    # test "can view account users" do
    #   get account_path(@account)
    #   assert_select "h1", @account.name
    #   assert_select "a", text: I18n.t("accounts.show.edit_account"), count: 1
    #   assert_select "a", text: I18n.t("accounts.show.edit"), count: @account.account_users.count + @account.account_invitations.count
    #   assert_select "a", text: I18n.t("accounts.show.invite"), count: 1
    # end

    test "can edit account user" do
      account_user = account_users(:company_regular_user)
      get edit_account_account_user_path(@account, account_user)
      assert_select "button", "Update Account user"
    end

    test "can update account user" do
      account_user = account_users(:company_regular_user)
      put account_account_user_path(@account, account_user), params: {account_user: {admin: "1"}}
      assert_response :redirect
      assert account_user.reload.admin?
    end

    test "can delete account users" do
      user = users(:two)
      user = @account.account_users.find_by(user: user)
      assert_difference "@account.account_users.count", -1 do
        delete account_account_user_path(@account, user.id)
      end
      assert_response :redirect
    end

    # rework for tokani user situations
    # test "disables admin role checkbox when editing owner" do
    #   account_user = account_users(:company_admin)
    #   get edit_account_account_user_path(@account, account_user)
    #   assert_select "input[type=checkbox][name='account_user[agency_admin]'][disabled]", 1
    # end
  end

  class RegularUsers < Jumpstart::AccountUsersTest
    setup do
      sign_in @regular_user
    end

    test "can view account users but not edit" do
      get account_path(@account)
      assert_select "h1", @account.name

      assert_select "a", text: I18n.t("accounts.show.edit_account"), count: 0
      assert_select "a", text: I18n.t("accounts.show.edit"), count: 0
      assert_select "a", text: "Invite A Account Member", count: 0
    end

    test "Regular user cannot view account user page" do
      get account_account_user_path(@account, @admin)
      assert_redirected_to account_path(@account)
    end

    # test "Regular user cannot edit account users" do
    #   # Cannot edit themselves
    #   account_user = @account.account_users.find_by(user: @regular_user)
    #   get edit_account_account_user_path(@account, account_user)
    #   assert_redirected_to account_path(@account)

    #   # Cannot edit admin user
    #   account_user = @account.account_users.find_by(user: @admin)
    #   get edit_account_account_user_path(@account, account_user)
    #   assert_redirected_to account_path(@account)
    # end

    # test "Regular user cannot update account users" do
    #   # Cannot edit themselves
    #   account_user = @account.account_users.find_by(user: @regular_user)
    #   put account_account_user_path(@account, account_user), params: {admin: "1"}
    #   assert_redirected_to account_path(@account)

    #   # Cannot edit admin user
    #   account_user = @account.account_users.find_by(user: @admin)
    #   put account_account_user_path(@account, account_user), params: {admin: "0"}
    #   assert_redirected_to account_path(@account)
    # end

    # test "Regular user cannot delete account users" do
    #   user = users(:one)
    #   account_user = @account.account_users.find_by(user: user)
    #   delete account_account_user_path(@account, account_user.id)
    #   assert_redirected_to account_path(@account)
    #   assert_includes @account.account_users.pluck(:user_id), user.id
    # end
  end

  class AgencyAdminAccountUsers < Jumpstart::AccountUsersTest
    setup do
      sign_in @agency_admin.user
    end

    test "agency admin has the cancel appointment option when an appointment is opened" do
      appointment = appointments(:one)
      get appointment_path(appointment)
      assert_select "a", text: "Cancel", count: 1
    end

    test "agency admin does not have any options to update a cancelled appointment" do
      appointment = appointments(:cancelled)
      get appointment_path(appointment)
      assert_select "a", text: "Open", count: 0
    end
  end

  class AgencyMemberAccountUsers < Jumpstart::AccountUsersTest
    setup do
      sign_in @agency_member.user
    end

    test "agency member has the cancel appointment option when an appointment is opened" do
      appointment = appointments(:one)
      get appointment_path(appointment)
      assert_select "a", text: "Cancel", count: 1
    end

    test "agency member does not have any options to update a cancelled appointment" do
      appointment = appointments(:cancelled)
      get appointment_path(appointment)
      assert_select "a", text: "Open", count: 0
    end
  end

  class CustomerAdminAccountUsers < Jumpstart::AccountUsersTest
    setup do
      sign_in @customer_admin.user
    end

    test "customer admin has the cancel appointment option when an appointment is opened" do
      appointment = appointments(:one)
      get appointment_path(appointment)
      assert_select "a", text: "Cancel", count: 1
    end

    test "customer admin does not have any options to update a cancelled appointment" do
      appointment = appointments(:cancelled)
      get appointment_path(appointment)
      assert_select "a", text: "Open", count: 0
    end
  end

  class CustomerMemberAccountUsers < Jumpstart::AccountUsersTest
    setup do
      sign_in @customer_member.user
    end

    test "customer member has the cancel appointment option when an appointment is opened" do
      appointment = appointments(:one)
      get appointment_path(appointment)
      assert_select "a", text: "Cancel", count: 1
    end

    test "customer member does not have any options to update a cancelled appointment" do
      appointment = appointments(:cancelled)
      get appointment_path(appointment)
      assert_select "a", text: "Open", count: 0
    end
  end
end
