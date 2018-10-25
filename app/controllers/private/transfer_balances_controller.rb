module Private
  class TransferBalancesController < BaseController
    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    def index
      @currencies = Currency.all
      @wallet_accounts = [['Exchange', 1], ['Lending', 2]]
      @all_balances = []

      Currency.codes.each do |code|
        exchange_balance = current_user.get_account(code).balance
        lending_balance = current_user.get_lending_account(code).balance
        total = exchange_balance + lending_balance
        @all_balances << {coin: code, ex: exchange_balance, lx: lending_balance, total: total}
      end

      if params[:commit].present?
        amount = params[:balance_transfer_amount].to_f
        selected_currency = params[:currency_field]
        from = params[:balance_transfer_from].to_f
        to = params[:balance_transfer_to].to_f

        selected_currency_code = Currency.find_by_id(selected_currency).code
        exchange = current_user.get_account(selected_currency_code)
        lending = current_user.get_lending_account(selected_currency_code)

        redirect_to transfer_balances_path, notice: t('private.transfer_balances.please_set_amount') and return unless amount.present?
        redirect_to transfer_balances_path, notice: t('private.transfer_balances.please_set_amount') and return unless amount > 0
        redirect_to transfer_balances_path, notice: t('private.transfer_balances.please_select_different_account') and return if from == to

        case from
        when 1
          redirect_to transfer_balances_path, notice: t('private.transfer_balances.not_enough_balance_exchange_account') and return if amount > exchange.balance
        when 2
          redirect_to transfer_balances_path, notice: t('private.transfer_balances.not_enough_balance_lending_account') and return if amount > lending.balance
        else
          redirect_to transfer_balances_path, alert: t('private.transfer_balances.error_selected_account') and return
        end

        if from == 1 and to == 2
          exchange.balance -= amount
          lending.balance += amount
        elsif from == 2 and to == 1
          exchange.balance += amount
          lending.balance -= amount
        else
          redirect_to transfer_balances_path, alert: t('private.transfer_balances.error_selected_account') and return
        end

        exchange.save # account
        lending.save

        redirect_to transfer_balances_path
      end
    end
  end
end
