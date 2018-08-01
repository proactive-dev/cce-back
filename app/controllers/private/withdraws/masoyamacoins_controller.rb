module Private::Withdraws
  class MasoyamacoinsController < ::Private::Withdraws::BaseController
    include ::Withdraws::Withdrawable
  end
end
