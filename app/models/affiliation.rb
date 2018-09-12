class Affiliation < ActiveRecord::Base
  extend Enumerize

  enumerize :state, in: {:wait => 0, :submitted => 100, :done => 200, :reject => -100}, scope: true

  validates_presence_of :affiliate, :referred
  validates_uniqueness_of :referred_id
  validates_numericality_of :amount, :greater_than_or_equal_to => 0

  WAIT = 'wait'
  SUBMITTED = 'submitted'
  DONE = 'done'
  REJECT = 'reject'

  belongs_to :affiliate, :class_name => "Member", :foreign_key => "affiliate_id"
  belongs_to :referred, :class_name => "Member", :foreign_key => "referred_id"

  scope :wait, -> { with_state(:wait) }
  scope :submitted, -> { with_state(:submitted) }

  private

  def validate
    raise "Affiliate and Referrer can't be the same user." if affiliate and (affiliate == referred)
  end

end