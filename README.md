#Chattr (Ruby)
A toy chat server written in Ruby that uses WebSocket as a communication medium. It borrows ORM from Rails' ActiveRecord to persist messages in MySQL on the server. A sample client is also provided for testing purposes.

##Requirements
Docker

##Execute Test Suite
1. docker-compose run server rake db:create && docker-compose run server rake db:migrate
2. docker-compose run server bundle exec rspec
