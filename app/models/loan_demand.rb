class LoanDemand < OpenLoan

  has_many :active_loans, foreign_key: 'demand_id'
  belongs_to :trigger_order

  scope :matching_rule, -> { order('rate ASC, created_at ASC') }

  def close_loans
    active_loans.each { |active_loan| active_loan.close }
  end

  def compute_locked
    0
  end

end