module Private
  module Deposits
    class MasoyamacoinsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
