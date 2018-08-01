module Admin
  module Withdraws
    class SakurabloomsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Sakurabloom'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24 * 7)
        @accepted_sakurablooms = @sakurablooms.with_aasm_state(:accepted).order("id DESC")
        @other_sakurablooms = @sakurablooms.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @sakurabloom.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @sakurabloom.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
