module Private::HistoryHelper

  def trade_side(trade)
    trade.ask_member == current_user ? 'sell' : 'buy'
  end

  def transaction_type(t)
    t(".#{t.class.superclass.name}")
  end

  def transaction_txid_link(t)
    return t.txid unless t.currency_obj.coin?

    txid = t.txid || ''
    link_to txid, t.blockchain_url
  end

  def loan_type(active_loan)
    active_loan.type_of(current_user.id)
  end

  def loan_auto_renew(active_loan)
    case loan_type(active_loan)
    when 'offer'
      t(".#{active_loan.auto_renew}")
    else
      '-'
    end
  end

  def loan_fee(active_loan)
    active_loan.fee(loan_type(active_loan))
  end
end
