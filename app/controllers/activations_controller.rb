class ActivationsController < ApplicationController
  include Concerns::TokenManagement

  before_action :auth_member!,    only: :new
  before_action :verified?,       only: :new
  before_action :token_required!, only: :edit

  def new
    current_user.send_activation
    redirect_to settings_path
  end

  def edit
    @token.confirm!

    if current_user
      url = "#{ENV['URL_SCHEMA']}://#{ENV['URL_UI']}/user"
    else
      url = "#{ENV['URL_SCHEMA']}://#{ENV['URL_UI']}/login"
    end
    redirect_to url, notice: t('.notice')
  end

  private

  def verified?
    if current_user.activated?
      redirect_to settings_path, notice: t('.verified')
    end
  end

end
