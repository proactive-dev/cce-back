module Verify
  class GoogleAuthsController < ApplicationController
    layout false

    skip_before_action :verify_authenticity_token
    before_action :auth_member!
    before_action :find_google_auth
    before_action :google_auth_inactivated?, only: [:edit, :destroy]

    def show
      if @google_auth.activated?
        render_json(GoogleAuthError.new(t(".notice.already_activated")))
       else
        render json: @google_auth, status: :ok
      end
    end

    def update
      if one_time_password_verified?
        @google_auth.active! and unlock_two_factor!
        render_json(GoogleAuthSuccess.new( t('.notice')))
      else
        render_json(GoogleAuthError.new(t(".alert")))
      end
    end

    def destroy
      if two_factor_auth_verified?
        @google_auth.deactive!
        render_json(GoogleAuthSuccess.new( t('.notice')))
      else
        render_json(GoogleAuthError.new(t(".alert")))
      end
    end

    private

    def find_google_auth
      @google_auth ||= current_user.app_two_factor
    end

    def google_auth_params
      params.require(:google_auth).permit(:otp)
    end

    def one_time_password_verified?
      @google_auth.assign_attributes(google_auth_params)
      @google_auth.verify?
    end

    def google_auth_inactivated?
      redirect_to settings_path, notice: t('.notice.not_activated_yet') if not @google_auth.activated?
    end

    def two_factor_required!
      return if not current_user.sms_two_factor.activated?

      if two_factor_locked?
        session[:return_to] = request.original_url
        redirect_to two_factors_path
      end
    end

  end
end
