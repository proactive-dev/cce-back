module Admin
  class ReferralsController < BaseController
    # load_and_authorize_resource

    def index
      @search_field = params[:search_field]
      @search_term = params[:search_term]
      @members = Member.search(field: @search_field, term: @search_term).page params[:page]
    end

    def show
      @member = Member.find params[:id]
      referrals = @member.referrals
      @ref_summaries = []
      Currency.all.each do |currency|
        commissions = referrals.blank? ? 0 : referrals.paid_sum(currency.code)
        rewards = 0
        @member.all_referees.each do |referee|
          tier = referee.get_tier(@member.id)
          commission = (ENV["REFERRAL_MAX_TIER"].to_i - tier) * ENV["REFERRAL_RATE_STEP"].to_d
          amount = referee.referrals.blank? ? 0 : referee.referrals.amount_sum(currency.code)
          rewards += amount * commission if amount > 0
        end
        @ref_summaries << {currency: currency.code.upcase, commissions: commissions, rewards: rewards}
      end
    end

    def tree
      @type = params[:type]
      @member = Member.find params[:id]
      @data = @type == 'referrers' ? @member.ref_uplines_admin : @member.ref_downlines_admin
    end
  end
end
