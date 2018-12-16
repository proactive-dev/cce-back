class TriggerBid < TriggerOrder

  scope :matching_rule, -> { order('price DESC, created_at ASC') }

end
