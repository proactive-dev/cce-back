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

  FUNS = {:unlock_funds => 1, :lock_funds => 2, :plus_funds => 3, :sub_funds => 4, :unlock_and_sub_funds => 5}

  belongs_to :member
  has_many :versions, class_name: "::AccountVersion"
  has_many :partial_trees

  # Suppose to use has_one here, but I want to store
  # relationship at account side. (Daniel)
  validates :member_id, uniqueness: { scope: :currency }
  # validates_numericality_of :balance, :borrowed, greater_than_or_equal_to: ZERO
  validates_numericality_of :locked, :borrow_locked, greater_than_or_equal_to: ZERO

  scope :enabled, -> { where("currency in (?)", Currency.ids) }
  scope :non_zero, -> { where("balance > ?", ZERO) }

  after_commit :trigger, :sync_update

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

  def plus_funds(amount, fee: ZERO, reason: nil, ref: nil)
    (amount <= ZERO or fee > amount) and raise MarginAccountError, "cannot add funds (amount: #{amount})"
    change_balance_and_locked amount, 0
  end

  def sub_funds(amount, fee: ZERO, reason: nil, ref: nil)
    (amount <= ZERO or amount > self.balance) and raise MarginAccountError, "cannot subtract funds (amount: #{amount})"
    change_balance_and_locked -amount, 0
  end

  def lock_funds(amount, reason: nil, ref: nil)
    (amount <= ZERO or amount > self.balance) and raise MarginAccountError, "cannot lock funds (amount: #{amount})"
    change_balance_and_locked -amount, amount
  end

  def unlock_funds(amount, reason: nil, ref: nil)
    (amount <= ZERO or amount > self.locked) and raise MarginAccountError, "cannot unlock funds (amount: #{amount})"
    change_balance_and_locked amount, -amount
  end

  def unlock_and_sub_funds(amount, locked: ZERO, fee: ZERO, reason: nil, ref: nil)
    raise MarginAccountError, "cannot unlock and subtract funds (amount: #{amount})" if ((amount <= 0) or (amount > locked))
    raise LockedError, "invalid lock amount" unless locked
    raise LockedError, "invalid lock amount (amount: #{amount}, locked: #{locked}, self.locked: #{self.locked})" if ((locked <= 0) or (locked > self.locked))
    change_balance_and_locked locked-amount, -locked
  end

  def plus_borrowed(amount, reason: nil, ref: nil)
    (amount <= ZERO) and raise BorrowedError, "cannot add borrowed (amount: #{amount})"
    change_borrowed amount, 0
  end

  def sub_borrowed(amount, reason: nil, ref: nil)
    (amount <= ZERO or amount > self.borrowed) and raise BorrowedError, "cannot sub borrowed (amount: #{amount})"
    change_borrowed -amount, 0
  end

  def lock_borrowed(amount, reason: nil, ref: nil)
    (amount < ZERO or amount > self.borrowed) and raise BorrowedError, "cannot lock borrowed (amount: #{amount})"
    change_borrowed -amount, amount
  end

  def unlock_borrowed(amount, reason: nil, ref: nil)
    (amount < ZERO or amount > self.borrow_locked) and raise BorrowedError, "cannot unlock borrowed (amount: #{amount})"
    change_borrowed amount, -amount
  end

  def return_borrowed(amount, interest, reason: nil, ref: nil)
    sub_borrowed amount, reason:reason, ref: ref
    sub_funds interest, fee: ZERO, reason: reason, ref: ref
  end

  after(*FUNS.keys) do |account, fun, changed, opts|
    begin
      opts ||= {}
      fee = opts[:fee] || ZERO
      reason = opts[:reason] || Account::UNKNOWN

      attributes = { fun: fun,
                     fee: fee,
                     reason: reason,
                     amount: account.amount,
                     currency: account.currency.to_sym,
                     member_id: account.member_id,
                     account_id: account.id }

      if opts[:ref] and opts[:ref].respond_to?(:id)
        ref_klass = opts[:ref].class
        attributes.merge! \
          modifiable_id: opts[:ref].id,
          modifiable_type: ref_klass.respond_to?(:base_class) ? ref_klass.base_class.name : ref_klass.name
      end

      locked, balance = compute_locked_and_balance(fun, changed, opts)
      attributes.merge! locked: locked, balance: balance

      AccountVersion.optimistically_lock_account_and_create!(account.balance, account.locked, attributes)
    rescue ActiveRecord::StaleObjectError
      Rails.logger.info "Stale account##{account.id} found when create associated account version, retry."
      account = Account.find(account.id)
      raise ActiveRecord::RecordInvalid, account unless account.valid?
      retry
    end
  end

  def self.compute_locked_and_balance(fun, amount, opts)
    raise MarginAccountError, "invalid account operation" unless FUNS.keys.include?(fun)

    case fun
    when :sub_funds then [ZERO, ZERO - amount]
    when :plus_funds then [ZERO, amount]
    when :lock_funds then [amount, ZERO - amount]
    when :unlock_funds then [ZERO - amount, amount]
    when :unlock_and_sub_funds
      locked = ZERO - opts[:locked]
      balance = opts[:locked] - amount
      [locked, balance]
    else raise MarginAccountError, "forbidden account operation"
    end
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

  def last_version
    versions.last
  end

  def examine
    expected = 0
    versions.find_each(batch_size: 100000) do |v|
      expected += v.amount_change
      return false if expected != v.amount
    end

    expected == self.amount
  end

  def trigger
    return unless member

    member.sync_margin_info('btc')
  end

  def change_balance_and_locked(delta_b, delta_l)
    self.balance += delta_b
    self.locked  += delta_l
    self.class.connection.execute "update margin_accounts set balance = balance + #{delta_b}, locked = locked + #{delta_l} where id = #{id}"
    add_to_transaction # so after_commit will be triggered
    self
  end

  def change_borrowed(delta_ba, delta_lo)
    self.borrowed  += delta_ba
    self.borrow_locked  += delta_lo
    self.class.connection.execute "update margin_accounts set borrowed = borrowed + #{delta_ba}, borrow_locked = borrow_locked + #{delta_lo} where id = #{id}"
    add_to_transaction # so after_commit will be triggered
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

  def as_json(options = {})
    super(options).merge({
      # check if there is a useable address, but don't touch it to create the address now.
      "deposit_address" => payment_addresses.empty? ? "" : payment_address.deposit_address,
      "name_text" => currency_obj.name_text,
      "default_withdraw_fund_source_id" => default_withdraw_fund_source_id,
      "tag" => payment_addresses.empty? ? "" : payment_address.tag
    })
  end

  private

  def sync_update
    ::Pusher["private-#{member.sn}"].trigger_async('margin_accounts', { type: 'update', id: self.id, attributes: {balance: balance, locked: locked, borrowed: borrowed, borrow_locked: borrow_locked} })
  end

end