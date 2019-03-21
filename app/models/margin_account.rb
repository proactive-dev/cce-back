class MarginAccount < ActiveRecord::Base
  include Currencible

  FIX = :fix
  UNKNOWN = :unknown
  STRIKE_ADD = :strike_add
  STRIKE_SUB = :strike_sub
  STRIKE_FEE = :strike_fee
  STRIKE_UNLOCK = :strike_unlock
  ORDER_CANCEL = :order_cancel
  ORDER_SUBMIT = :order_submit
  ORDER_FULLFILLED = :order_fullfilled
  LOAN_MATCHED = :loan_matched
  LENDING_DONE = :lending_done
  ZERO = 0.to_d

  belongs_to :member

  validates :member_id, uniqueness: { scope: :currency }
  # validates_numericality_of :balance, :borrowed, greater_than_or_equal_to: ZERO
  validates_numericality_of :locked, :borrow_locked, greater_than_or_equal_to: ZERO

  scope :enabled, -> { where("currency in (?)", Currency.ids) }
  scope :non_zero, -> { where("balance > ?", ZERO) }

  def self.after(*names)
    names.each do |name|
      m = instance_method(name.to_s)
      define_method(name.to_s) do |*args, &block|
        m.bind(self).(*args, &block)
        yield(self, name.to_sym, *args)
        self
      end
    end
  end

  def sub_funds(amount, reason: nil, ref: nil)
    amount < ZERO and raise BorrowedError, "cannot sub borrowed (amount: #{amount})"
    self.balance -= amount
    self.save!
  end

  def plus_borrowed(amount, reason: nil, ref: nil)
    amount < ZERO and raise BorrowedError, "cannot add borrowed (amount: #{amount})"
    change_borrowed amount, 0
  end

  def sub_borrowed(amount, reason: nil, ref: nil)
    amount < ZERO and raise BorrowedError, "cannot sub borrowed (amount: #{amount})"
    change_borrowed -amount, 0
  end

  def lock_borrowed(amount, reason: nil, ref: nil)
    amount < ZERO and raise BorrowedError, "cannot lock borrowed (amount: #{amount})"
    change_borrowed -amount, amount
  end

  def unlock_borrowed(amount, reason: nil, ref: nil)
    amount < ZERO and raise BorrowedError, "cannot unlock borrowed (amount: #{amount})"
    change_borrowed amount, -amount
  end

  def unlock_and_sub_borrowed(amount, locked: ZERO, fee: ZERO, reason: nil, ref: nil)
    raise MarginAccountError, "cannot unlock and subtract funds (amount: #{amount})" if ((amount <= 0) or (amount > locked))
    raise LockedError, "invalid lock amount" unless locked
    raise LockedError, "invalid lock amount (amount: #{amount}, locked: #{locked}, self.locked: #{self.locked})" if ((locked <= 0) or (locked > self.borrow_locked))
    change_borrowed locked-amount, -locked
  end

  def return_borrowed(amount, interest, reason: nil, ref: nil)
    sub_borrowed amount, reason:reason, ref: ref
    sub_funds interest, reason: reason, ref: ref
  end

  def tradable_balance
    self.balance + self.borrowed
  end

  def all_amount
    self.balance + self.borrowed + self.locked + self.borrow_locked
  end

  def amount
    self.balance + self.locked
  end

  def change_borrowed(delta_ba, delta_lo)
    self.borrowed  += delta_ba
    self.borrow_locked  += delta_lo
    self.class.connection.execute "update margin_accounts set borrowed = borrowed + #{delta_ba}, borrow_locked = borrow_locked + #{delta_lo} where id = #{id}"
    add_to_transaction
    self
  end

  scope :locked_sum, -> (currency) { with_currency(currency).sum(:locked) }
  scope :balance_sum, -> (currency) { with_currency(currency).sum(:balance) }

  scope :borrowed_sum, -> (currency) { with_currency(currency).sum(:borrowed) }
  scope :borrow_locked_sum, -> (currency) { with_currency(currency).sum(:borrow_locked) }

  class MarginAccountError < RuntimeError; end
  class LockedError < MarginAccountError; end
  class BalanceError < MarginAccountError; end
  class BorrowedError < MarginAccountError; end
  class BorrowLockedError < MarginAccountError; end

  private

end