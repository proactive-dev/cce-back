module Private
  class PositionsController < BaseController

    def update
      ActiveRecord::Base.transaction do
        position = current_user.positions.find(params[:id])
        amount = params[:amount].to_f

        if position.present?
          position.close(amount)
          render status: 200, nothing: true
        else
          render status: 500, nothing: true
        end
      end
    end
  end
end
