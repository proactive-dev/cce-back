class Affiliation < ActiveRecord::Base
  belongs_to :affiliate, :class_name => "Member", :foreign_key => "affiliate_id"
  belongs_to :referred, :class_name => "Member", :foreign_key => "referred_id"

  validates_presence_of :affiliate, :referred
  validates_uniqueness_of :referred_id

  private

  def validate
    raise "Affiliate and Referrer can't be the same user." if affiliate and (affiliate == referred)
  end

end