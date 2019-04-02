class WithdrawBlacklistValidator < ActiveModel::Validator

  def validate(record) # Temporarily stop!!
    # return if record.currency_obj.blacklist.blank?
    # if record.currency_obj.blacklist.include?(record.fund_uid)
    #   record.errors[:fund_uid] << I18n.t('withdraws.invalid_address')
    # end
  end

end
