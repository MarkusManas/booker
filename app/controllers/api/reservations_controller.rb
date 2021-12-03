class Api::ReservationsController < ApiController

  before_action :get_reservation, except: [:index]

  def index
    @reservations = Reservation.all
    render json: {"reservations": @reservations}, status: 200
  end

  def create
    @reservation = Reservation.new(parse_payload(reservation_params))
    @reservation.guest = Guest.find_by(email: @reservation.guest_email) rescue Guest.create(email: @reservation.guest_email)
    if @reservation.save
      render json: @reservation.as_json, status: 200
    else
      render json: {msg: @reservation.errors.full_messages}, status: 400
    end
  end

  def show
    if @reservation.present?
      render json: @reservation, status: 200
    else
      render json: {msg: 'Reservation not found.'}, status: 404
    end
  end

  def update
    if @reservation.update_attributes(parse_payload(reservation_params))
      # if email was updated, adjust foreign key accordingly
      if parse_payload(reservation_params)[:guest_email].present?
        @reservation.guest = Guest.find_by(email: @reservation.guest_email) rescue Guest.create(email: @reservation.guest_email)
        if !@reservation.save
          render json: {msg: @reservation.errors.full_messages}, status: 400
          return
        end
      end
      render json: @reservation, status: 200
    else
      render json: {msg: @reservation.errors.full_messages}, status: 400
    end
  end

  def destroy
    if @reservation.destroy
      render json: {msg: 'Reservation deleted.'}, status: 200
    else
      render json: {msg: 'Reservation not found.'}, status: 404
    end
  end
  
  private

  # stumped how to implement this, a changing, scalable payload contradicts what i know about strong params, ask this if i get the chance
  def reservation_params
    params.except(:action, :controller).permit!
  end

  def get_reservation
    # get reservation by db id, reservation code if fail
    @reservation = Reservation.find(params[:id]) rescue nil
    if @reservation.blank?
      @reservation = Reservation.find_by(reservation_code: params[:id]) rescue nil
    end
  end

  def parse_payload(payload)
    # Flatten payload including path
    parsed = flatten_payload(payload.to_hash.with_indifferent_access, nil).with_indifferent_access
    # fetch the keys important fields here
    code_key = parsed.keys.select{ |i| i[/code/]}.first rescue nil
    email_key = parsed.keys.select{ |i| i[/guest_email/]}.first rescue nil
    start_date_key = parsed.keys.select{ |i| i[/start_date/]}.first rescue nil
    end_date_key = parsed.keys.select{ |i| i[/end_date/]}.first rescue nil
    # replace key to a standard key for database insertion
    parsed[:reservation_code] = parsed.delete "#{code_key}"
    parsed[:guest_email] = parsed.delete "#{email_key}"
    parsed[:start_date] = parsed.delete "#{start_date_key}"
    parsed[:end_date] = parsed.delete "#{end_date_key}"
    
    return parsed
  end

  def flatten_payload(payload, path=nil)
    flattened = {}

    payload.each_with_index do |item, i|
      # get key value pair for nested hashes
      if item.is_a? Array
        k, v = item
      else
        k, v = i, item
      end

      #if nested hash then add key to path
      new_path = path ? "#{path}_#{k}" : k

      if v.is_a? Enumerable
        flattened.merge!(flatten_payload(v, new_path))
      else
        # base condition of recursion, make path key for hash
        flattened[new_path] = v
      end
    end
    return flattened
  end
end
