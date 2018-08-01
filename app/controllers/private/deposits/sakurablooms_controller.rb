module Private
  module Deposits
    class SakurabloomsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
