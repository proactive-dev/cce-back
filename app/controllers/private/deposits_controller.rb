module Private
  class DepositsController < BaseController
    layout 'app'
    before_action :auth_activated!
    before_action :auth_verified!

    def gen_address
      account = current_user.get_account(currency.code)
      if !account.payment_address.transactions.empty?
        @address = account.payment_addresses.create currency: account.currency
        @address.gen_address if @address.address.blank?
        render nothing: true
      else
        render text: t('.require_transaction'), status: 403
      end

    end

    def destroy
      record = current_user.deposits.find(params[:id]).lock!
      if record.cancel!
        head 204
      else
        head 422
      end
    end

    private

    def currency
      @currency ||= Currency.find_by_code(params[:currency])
    end
  end
end
