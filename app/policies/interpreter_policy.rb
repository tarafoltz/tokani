# frozen_string_literal: true

class InterpreterPolicy < ApplicationPolicy
  def show_side_nav? controller_name
    pure_interpreter? && whitelisted_controllers.include?(controller_name)
  end

  def show_account_nav?
    pure_interpreter?
  end

  private

  # show sidenav only on these controllers
  def whitelisted_controllers
    %w[dashboard interpreters time_offs]
  end

  def pure_interpreter?
    @account_user&.interpreter?
  end
end
