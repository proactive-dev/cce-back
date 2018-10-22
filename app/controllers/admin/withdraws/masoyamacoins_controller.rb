module Admin
  module Withdraws
    class MasoyamacoinsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Masoyamacoin'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24 * 7)
        @pending_masoyamacoins = @masoyamacoins.with_aasm_state(:accepted).order("id DESC")
        @other_masoyamacoins = @masoyamacoins.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @masoyamacoin.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @masoyamacoin.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
