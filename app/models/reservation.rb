class Reservation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  
  # important fields, rest can be dynamic
  field :reservation_code, type: String
  field :guest_email, type: String
  field :start_date, type: String
  field :end_date, type: String

  belongs_to :guest

  validates_presence_of :reservation_code
  validates_presence_of :guest_email
	validates_uniqueness_of :reservation_code
  validate :validate_date
	
  index({ reservation_code: 1 },   { unique: true })
  # add unique index for start date to avoid double reservation since single site cannot host more than 1 reservation
  # if it was an endpoint that receives a house id, cannot do this since multiple dates can be booked across different houses
  # index dates so that mongodb does an index scan instead of collection scan
  index({ start_date: 1 },   { unique: true })
  index({ end_date: 1 },   { unique: true })


  def validate_date
    # validate overlaps
    # date is completely within existing reservation date
    first_checker = Reservation.where(:start_date.gte => self.start_date, :end_date.lte => self.end_date).not.where(id: self._id).count
    # date is right side overlap against existing reservation date
    second_checker = Reservation.where(:start_date.gte => self.start_date, :start_date.lte => self.end_date).not.where(id: self._id).count
    # date is left side overlap against existing reservation date
    third_checker = Reservation.where(:end_date.gte => self.start_date, :end_date.lte => self.end_date).not.where(id: self._id).count
    # date swallows existing reservation date
    fourth_checker = Reservation.where(:start_date.lte => self.start_date, :end_date.gte => self.end_date).not.where(id: self._id).count
  
    if [first_checker, second_checker, third_checker, fourth_checker].any? { |x| x > 0}
      errors.add(:date, 'Reservation overlaps with an existing reservation.')
    end

    # validate start date and end date
    if self.start_date > self.end_date
      errors.add(:start_date, ' cannot be after end_date')
    end
  end
end