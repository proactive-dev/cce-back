module Private
  class DepositsController < BaseController
    layout 'app'
    before_action :auth_activated!
    before_action :auth_verified!

    def destroy
      record = current_user.deposits.find(params[:id]).lock!
      if record.cancel!
        head 204
      else
        head 422
      end
    end
  end
end
