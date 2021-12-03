class Guest
  include Mongoid::Document

  field :email, type: String

  has_many :reservations

  validates_presence_of :email
	validates_uniqueness_of :email

  index({ email: 1 },   { unique: true })
end
