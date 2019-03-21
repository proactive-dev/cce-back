module Authentications
  class IdentitiesController < ApplicationController

    layout false

    before_action :auth_member!

    def new
      @identity = Identity.new(email: current_user.email)
    end

    def create
      identity = Identity.new(identity_params.merge(email: current_user.email))
      if identity.save && current_user.create_auth_for_identity(identity)
        render_json(SetupPasswordSuccess.new(t('.success')))
      else
        render_json(AuthError.new)
      end
    end

    private

    def identity_params
      params.required(:identity).permit(:password, :password_confirmation)
    end

  end
end
