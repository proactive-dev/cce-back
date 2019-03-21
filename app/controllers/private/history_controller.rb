module Private
  class HistoryController < BaseController
    layout false

    # helper_method :tabs

    def account
      @market = current_market

      @deposits = Deposit.where(member: current_user).with_aasm_state(:accepted)
      @withdraws = Withdraw.where(member: current_user).with_aasm_state(:done)

      @transactions = (@deposits + @withdraws).sort_by {|t| -t.created_at.to_i }
      @transactions = Kaminari.paginate_array(@transactions).page(params[:page]).per(20)
    end

    def trades
      trades = current_user.trades.where('created_at > ?', 2.months.ago)
      if params[:search]
        trades = trades.where(params[:search])
        render json: {
          member_id: current_user.id,
          total_length: trades.length,
          trades: trades.order('id desc').page(params[:page]).per(params[:perPage]).map(&:for_history)
        }
      else
        render json: {
          member_id: current_user.id,
          trades: trades.order('id desc').map(&:for_history)
        }
      end
    end

    def orders
      orders = current_user.orders.where('created_at > ?', 2.months.ago)
      if params[:search]
        orders = orders.where(params[:search])
        render json: {
          total_length: orders.length,
          orders: orders.order("id desc").page(params[:page]).per(params[:perPage]).map(&:for_notify)
        }
      else
        render json: {
          orders: orders.order("id desc").map(&:for_notify)
        }
      end
    end

    def loans
      @loans = current_user.active_loans
                   .where('state = ?', 200) # state : DONE
                   .includes(:demand_member).includes(:offer_member)
                   .order('id desc').page(params[:page]).per(20)
    end

    # private

    # def tabs
    #   {
    #       order: ['header.order_history', order_history_path],
    #       trade: ['header.trade_history', trade_history_path],
    #       account: ['header.account_history', account_history_path],
    #       loan: ['header.loan_history', loan_history_path]
    #   }
    # end

  end
end
