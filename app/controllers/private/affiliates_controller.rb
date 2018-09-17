module Private
  class AffiliatesController < BaseController
    layout 'affiliate'

    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!
    before_action :check_affiliate!, only: :index

    def index
      @affiliate_url = current_user.affiliate_url if @affiliate_url.nil?
      @banners = Banner.all
      @affiliation_count = current_user.affiliations.count
      @commissions = current_user.affiliations.sum(:amount)
      @affiliations = current_user.affiliations
                    .order('id desc').page(params[:page]).per(10)
      render :index
    end

    def gen_affiliate_code
      current_user.generate_affiliate_code unless current_user.is_affiliate?
      if current_user.affiliate_code
        redirect_to affiliates_path
      else
        redirect_to about_affiliate_path
      end
    end

    private

    def check_affiliate!
      redirect_to about_affiliate_path unless current_user.is_affiliate?
    end

  end
end
