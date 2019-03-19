class IdentitiesController < ApplicationController

  layout false

  skip_before_action :verify_authenticity_token
  # before_filter :auth_anybody!, only: :new

  def new
    @identity = env['omniauth.identity'] || Identity.new
  end

  def edit
    @identity = current_user.identity
  end

  def update
    @identity = current_user.identity

    unless @identity.authenticate(params[:identity][:old_password])
      render_json(IdentityUpdateError.new(t('.auth-error')))
      return
    end

    if @identity.authenticate(params[:identity][:password])
      render_json(IdentityUpdateError.new(t('.auth-same')))
      return
    end

    if @identity.update_attributes(identity_params)
      current_user.send_password_changed_notification
      clear_all_sessions current_user.id
      reset_session
      render_json(SetupPasswordSuccess.new(t('.notice')))
    else
      render_json(AuthError.new)
    end
  end

  def failure
    if env['omniauth.identity'].present? && env['omniauth.identity'].errors.present?
      render_json(SignUpFailure.new(env['omniauth.identity'].errors))
    else
      render_json(SignUpFailure.new('Signup Failed'))
    end
  end

  private
  def identity_params
    params.required(:identity).permit(:password, :password_confirmation)
  end
end
