class TriggerAsk < TriggerOrder

  scope :matching_rule, -> { order('price ASC, created_at ASC') }

end
