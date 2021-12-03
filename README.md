# README

* Ruby version: 2.6.3

* System dependencies: 
    rails, 
    mongodb,
    bundle

* start instructions
    - Make sure gems are installed by running `bundle install`
    - If first time set up, run `rails db:mongoid:create_indexes`
    - Start mongodb
    - Start rails `rails s`
    Api will be listening by default on port 3000
    Open postman and start making requests on localhost:3000/api/reservations

* requirements to create a reservation:
    Guest must exist (if guest email doesnt exist then api will create guest having the sent email)
    Cannot make a reservation if start date clashes with any startdate->enddate of any existing reservation