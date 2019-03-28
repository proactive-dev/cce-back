module Private
  class ReferralsController < BaseController
    layout false

    def index
      render json: current_user.referral_info, status: :ok
    end
  end
end

