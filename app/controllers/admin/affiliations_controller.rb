module Admin
  class AffiliationsController < BaseController
    load_and_authorize_resource :class => '::Affiliation'

    def index
      start_at = DateTime.now.ago(60 * 60 * 24 * 31)
      @submitted_affiliations = @affiliations.with_state(:submitted).order("id DESC")
      @other_affiliations = @affiliations.without_state(:submitted).where('created_at > ?', start_at).order("id DESC")
    end

    def show
    end

    def update
      @affiliation.approve
      redirect_to :back, notice: t('.notice')
    end

    def destroy
      @affiliation.reject
      redirect_to :back, notice: t('.notice')
    end
  end
end
