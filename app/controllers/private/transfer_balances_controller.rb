module Private
  class TransferBalancesController < BaseController
    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    def index
      @currencies = Currency.all
      @account_types = ['exchange', 'margin', 'lending']
      # @account_types = [['Exchange', 1], ['Margin', 2], ['Lending', 3]]
      @all_accounts = []

      Currency.codes.each do |code|
        exchange_balance = current_user.get_account(code).balance
        margin_balance = current_user.get_margin_account(code).balance
        lending_balance = current_user.get_lending_account(code).balance
        total = exchange_balance + margin_balance + lending_balance
        @all_accounts << {currency: code, exchange: exchange_balance, margin: margin_balance, lending: lending_balance, total: total}
      end

      if params[:commit].present?
        amount = params[:amount_to_transfer].to_f
        selected_currency = params[:currency]
        from_account_type = params[:from_account_type]
        to_account_type = params[:to_account_type]

        redirect_to transfer_balances_path, notice: t('private.transfer_balances.please_set_amount') and return unless (amount.present? && amount > 0)
        redirect_to transfer_balances_path, notice: t('private.transfer_balances.please_select_different_account') and return if from_account_type == to_account_type

        selected_currency_code = Currency.find_by_id(selected_currency).code
        from_account = current_user.send("get_#{from_account_type}_account", selected_currency_code)
        to_account = current_user.send("get_#{to_account_type}_account", selected_currency_code)

        redirect_to transfer_balances_path, notice: t('private.transfer_balances.not_enough_balance_source_account') and return if amount > from_account.balance

        from_account.balance -= amount
        to_account.balance += amount

        from_account.save!
        to_account.save!

        redirect_to transfer_balances_path
      end
    end
  end
end
