class Loaning

  class CancelLoanError < StandardError; end

  def initialize(loan_or_loans)
    @loans = Array(loan_or_loans)
  end

  def submit
    ActiveRecord::Base.transaction do
      @loans.each {|loan| do_submit loan }
    end

    @loans.each do |loan|
      AMQPQueue.enqueue(:loan_matching, action: 'submit', loan: loan.to_matching_attributes)
    end

    true
  end

  def update
    @loans.each {|loan| do_update loan }
  end

  def cancel
    @loans.each {|loan| do_cancel loan }
  end

  def reject
    @loans.each {|loan| do_reject loan }
  end

  def update!
    ActiveRecord::Base.transaction do
      @loans.each {|loan| do_update! loan }
    end
  end

  def cancel!
    ActiveRecord::Base.transaction do
      @loans.each {|loan| do_cancel! loan }
    end
  end

  def reject!
    ActiveRecord::Base.transaction do
      @loans.each {|loan| do_reject! loan }
    end
  end

  private

  def do_submit(loan)
    loan.fix_number_precision # number must be fixed before computing locked
    loan.save!

    account = loan.hold_lending_account
    account.lock_funds(loan.compute_locked, reason: LendingAccount::LOAN_SUBMIT, ref: loan)
  end

  def do_cancel(loan)
    AMQPQueue.enqueue(:loan_matching, action: 'cancel', loan: loan.to_matching_attributes)
  end

  def do_update(loan)
    AMQPQueue.enqueue(:loan_matching, action: 'update', loan: loan.to_matching_attributes)
  end

  def do_reject(loan)
    AMQPQueue.enqueue(:loan_matching, action: 'reject', loan: loan.to_matching_attributes)
  end

  def do_cancel!(loan)
    account = loan.hold_lending_account
    loan   = OpenLoan.find(loan.id).lock!

    if loan.state == OpenLoan::WAIT
      loan.state = OpenLoan::CANCEL
      account.unlock_funds(loan.compute_locked, reason: LendingAccount::LOAN_CANCEL, ref: loan)
      loan.save!
    else
      raise CancelLoanError, "Only active loan can be cancelled. id: #{loan.id}, state: #{loan.state}"
    end
  end

  def do_reject!(loan)
    account = loan.hold_lending_account
    loan   = OpenLoan.find(loan.id).lock!

    if loan.state == OpenLoan::WAIT
      loan.state = OpenLoan::REJECT
      account.unlock_funds(loan.compute_locked, reason: LendingAccount::LOAN_CANCEL, ref: loan)
      loan.save!
    else
      raise CancelLoanError, "Only active loan can be cancelled. id: #{loan.id}, state: #{loan.state}"
    end
  end

  def do_update!(loan)
    loan = OpenLoan.find(loan.id).lock!
    loan.auto_renew = !loan.auto_renew
    loan.save!
  end

end
