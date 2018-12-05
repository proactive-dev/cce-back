class TriggerAsk < TriggerOrder

  scope :matching_rule, -> { order('price ASC, created_at ASC') }

  # def get_account_changes(order)
  #   [order.volume, order.funds]
  # end

  # def hold_account
  #   member.get_account(ask)
  # end
  #
  # def expect_account
  #   member.get_account(bid)
  # end

  # def avg_price
  #   return ::Global::ZERO if funds_used.zero?
  #   config.fix_number_precision(:bid, funds_received / funds_used)
  # end

  # def compute_locked
  #   case ord_type
  #   when 'limit'
  #     volume
  #   when 'market'
  #     estimate_required_funds(Global[currency].bids) {|p, v| v}
  #   end
  # end

end
