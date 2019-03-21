class ResetPasswordsController < ApplicationController

  layout false

  include Concerns::TokenManagement

  skip_before_action :verify_authenticity_token
  before_action :auth_anybody!
  before_action :token_required, :only => [:show, :update]

  def create
    @token = Token::ResetPassword.new(reset_password_params)

    if @token.save
      clear_all_sessions @token.member_id
      render_json(ResetPasswordSuccess.new(t('.success')))
    else
      render_json(ResetPasswordFailure.new(@token.errors.full_messages.join(', ')))
    end
  end

  def show
    render_json(ResetPasswordSuccess.new(t('.submit')))
  end

  def update
    if @token.update_attributes(reset_password_update_params)
      @token.confirm!
      render_json(ResetPasswordSuccess.new(t('.success')))
    else
      render_json(ResetPasswordFailure.new(@token.errors.full_messages.join(', ')))
    end
  end

  private
  def reset_password_params
    params.required(:reset_password).permit(:email)
  end

  def reset_password_update_params
    params.required(:reset_password).permit(:password)
  end
end
