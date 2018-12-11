module Private
  class PositionsController < BaseController

    def update
      ActiveRecord::Base.transaction do
        position = current_user.positions.find(params[:id])
        amount = params[:amount]

        # TODO: Close position

        render status: 200, nothing: true
      end
    end
  end
end
