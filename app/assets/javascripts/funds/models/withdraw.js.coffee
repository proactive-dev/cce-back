class Withdraw extends ExchangeModel.Model
  @configure 'Withdraw', 'sn', 'account_id', 'member_id', 'currency', 'amount', 'fee', 'fund_uid', 'fund_extra',
    'created_at', 'updated_at', 'done_at', 'txid', 'blockchain_url', 'aasm_state', 'sum', 'type', 'is_submitting'

  constructor: ->
    super
    @is_submitting = @aasm_state == "submitting"

  @initData: (records) ->
    ExchangeModel.Ajax.disable ->
      $.each records, (idx, record) ->
        Withdraw.create(record)

  afterScope: ->
    "#{@pathName()}"

  pathName: ->
    switch @currency
      when 'usd' then 'dollars'
      when 'btc' then 'satoshis'
      when 'eth' then 'ethereums'
      when 'ltc' then 'litecoins'
      when 'skb' then 'sakurablooms'
      when 'mas' then 'masoyamacoins'
window.Withdraw = Withdraw
