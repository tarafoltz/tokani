module CurrentHelper
  def current_account
    Current.account
  end

  def current_account_user
    return unless current_account
    @account_user ||= current_account.account_users.includes(:user).find_by(user: current_user)
  end

  def current_roles
    current_account_user&.active_roles || []
  end

  def customer_logged_in?
    current_account_user&.customer_admin?
  end

  def agency_logged_in?
    current_account_user&.agency_admin? || current_account_user&.agency_member?
  end

  def requestor_logged_in?
    current_account_user&.site_admin? || current_account_user&.site_member? || current_account_user&.client? || current_account_user&.customer_admin?
  end

  def current_account_admin?
    !!current_account_user&.admin?
  end

  def other_accounts
    @_other_accounts ||= current_user.accounts.order(name: :asc).where.not(id: current_account.id)
  end
end
