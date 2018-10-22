module Admin
  module Assets
    class PaymentAddressesController < BaseController
      load_and_authorize_resource

      def index
        @payment_addresses = @payment_addresses.order('id desc').page params[:page]
      end

      def show
        @proofs = Proof.where(currency: @payment_address.currency_obj.id)
        @amount = params[:amount]
        @to_address = params[:to_address]

        return unless params[:commit].present?

        if @amount.blank? || @to_address.blank?
          redirect_to :back, alert: 'Invalid input data'
        else
          begin
            redirect_to :back, alert: 'Invalid address' and return if @payment_address.address.blank? || @payment_address.currency_obj.blank?

            balance = @payment_address.currency_obj.api.load_balance_of!(@payment_address.address)
            @payment_address.update! balance: balance

            redirect_to :back, alert: 'Insufficient balance!' and return if balance < @amount.to_d

            recipient = { address: @to_address }
            # recipient[:tag]= @tag unless @tag.nil?

            txid = @payment_address.currency_obj.api.create_withdrawal!(
                { address: @payment_address.address, secret: @payment_address.secret, tag: @payment_address.tag },
                recipient,
                @amount.to_d
            )

            if txid
              balance = @payment_address.currency_obj.api.load_balance_of!(@payment_address.address)
              @payment_address.update! balance: balance

              redirect_to admin_assets_payment_addresses_path, notice: "Transfer succeed! Txid: #{txid}"
            else
              redirect_to :back, alert: 'Transfer failed!'
            end
          rescue StandardError => e
            notification = "Failed to transfer #{@amount}#{@payment_address.currency}: #{e.inspect}."
            Rails.logger.info notification

            redirect_to :back, alert: notification
          ensure
          end
        end
      end

      private

      def proof_params
        params.required(:proof).permit(:balance)
      end

    end
  end
end
