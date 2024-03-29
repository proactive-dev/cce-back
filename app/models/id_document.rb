class IdDocument < ActiveRecord::Base
  extend Enumerize
  include AASM
  include AASM::Locking

  has_one :id_document_file, class_name: 'Asset::IdDocumentFile', as: :attachable
  accepts_nested_attributes_for :id_document_file

  has_one :id_bill_file1, class_name: 'Asset::IdBillFrontFile', as: :attachable
  accepts_nested_attributes_for :id_bill_file1

  has_one :id_bill_file2, class_name: 'Asset::IdBillBackFile', as: :attachable
  accepts_nested_attributes_for :id_bill_file2

  has_one :id_selfie_file, class_name: 'Asset::IdSelfieFile', as: :attachable
  accepts_nested_attributes_for :id_selfie_file

  belongs_to :member

  validates_presence_of :name, :id_document_type, :id_document_number, :id_bill_type, :gender, allow_nil: true
  validates_uniqueness_of :member

  enumerize :id_document_type, in: {id_card: 0, passport: 1, driver_license: 2}
  enumerize :id_bill_type,     in: {bank_statement: 0, tax_bill: 1}
  enumerize :gender,     in: {male: 1, female: 2}

  alias_attribute :full_name, :name

  aasm do
    state :unverified, initial: true
    state :verifying
    state :verified

    event :submit do
      transitions from: :unverified, to: :verifying
    end

    event :approve do
      transitions from: [:unverified, :verifying],  to: :verified
    end

    event :reject do
      transitions from: [:verifying, :verified],  to: :unverified
    end
  end
end
