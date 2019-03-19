module Private
  class SettingsController < BaseController
    layout false

    def index

      data ={
          email: current_user.email,
          activation_status: current_user.activated?,
          verification_status: current_user.id_document_verified?,
          sms_status: current_user.sms_two_factor.activated?,
          tfa_status: current_user.app_two_factor.activated?,
          is_admin: current_user.admin?,
          tags: current_user.tag_list,
          signup_histories: current_user.signup_histories.last(10)
      }

      render json: data.to_json, status: :ok
    end
  end
end

