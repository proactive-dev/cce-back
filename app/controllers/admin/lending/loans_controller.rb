module Admin
  module Lending
    class LoansController < ::Admin::BaseController
      skip_load_and_authorize_resource

      def index
        @demands = OpenLoan.all.with_state(:wait).where('type = ?', 'LoanOffer').order("id DESC")
        @offers = OpenLoan.all.with_state(:wait).where('type = ?', 'LoanDemand').order("id DESC")
      end

      def destroy
        @loan = OpenLoan.find(params[:id])
        Loaning.new(@loan).reject
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
