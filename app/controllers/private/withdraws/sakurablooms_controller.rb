module Private::Withdraws
  class SakurabloomsController < ::Private::Withdraws::BaseController
    include ::Withdraws::Withdrawable
  end
end
