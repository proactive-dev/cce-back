module Private
  class AffiliatesController < BaseController
    layout 'affiliate'

    before_action :check_affiliate!, only: :index

    def index
      @affiliate_url = current_user.affiliate_url if @affiliate_url.nil?
      @banners = ['affi_04', 'affi_04']
      @affiliation_count = 0
      @commissions = 0
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
