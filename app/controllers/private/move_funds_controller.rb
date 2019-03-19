module Private
  class MoveFundsController < BaseController
    layout false

    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    def create
      amount = params[:amount].to_f
      selected_currency = params[:currency]
      from_account_type = params[:from_acc_type].downcase
      to_account_type = params[:to_acc_type].downcase

      render_json(MoveFundsFailure.new(t('private.move_funds.please_set_amount'))) and return unless (amount.present? && amount > 0)
      render_json(MoveFundsFailure.new(t('private.move_funds.please_select_different_account'))) and return if (from_account_type == to_account_type)

      from_account = current_user.send("get_#{from_account_type}_account", selected_currency)
      to_account = current_user.send("get_#{to_account_type}_account", selected_currency)

      render_json(MoveFundsFailure.new(t('private.move_funds.not_enough_balance_source_account'))) and return if amount > from_account.balance

      from_account.balance -= amount
      to_account.balance += amount

      from_account.save!
      to_account.save!

      render_json(MoveFundsSuccess.new)
    end
  end
end
