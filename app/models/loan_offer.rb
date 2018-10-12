class LoanOffer < OpenLoan

  has_many :active_loans, foreign_key: 'offer_id'

  scope :matching_rule, -> { order('rate DESC, created_at ASC') }

  def compute_locked
    amount
  end

end
