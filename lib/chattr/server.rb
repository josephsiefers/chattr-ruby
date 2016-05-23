require 'websocket-eventmachine-server'
require 'json'
require 'cgi'
require 'chattr/user'

module Chattr
  class Server 

    def initialize(host, port)
      @connections = {} #maps a user_name to a list of connections
      @user_names = {} #maps a connection to its user_name owner
      @host = host
      @port = port
    end

    def start
      EM.run do
        puts "Starting up the server..."
        WebSocket::EventMachine::Server.start(:host => @host, :port => @port) do |ws|
          ws.onopen do |handshake|
            params = CGI::parse(handshake.query)
            user_name = params["user_name"].first

            #authentication with password would take place here
            #assumedly, the user would register for the service in a different step but for simplicity we just create the account if necessary.
            user = User.find_or_create_by(user_name: user_name)
            #user.validate_password(params["password"])

            puts "Server: device for #{user_name} connected"
            @user_names[ws] = user_name
            @connections[user_name].nil? ? @connections[user_name] = [ws] : @connections[user_name] << ws
          end

          ws.onmessage do |msg, type|
            msg_json = JSON.parse(msg)

            #For the purposes of this exercise we send the chat history through websocket. I would probably actually prefer to do this via a GET user/:id/messages?after=:timestamp API request in a real world app (more natural pagination)
            if msg_json["request"] == "history"
              deliver_history(ws, msg_json["timestamp"])
            else
              #In the real world, a client might be required to look up recipient id in some kind of external directory service and pass it as a param. For the purposes of this exercise, we just use user_name
              sender_user_name = @user_names[ws]
              deliver_message(msg_json["recipient_user_name"], sender_user_name, msg_json["msg"])
            end
          end

          ws.onclose do
            user_name = @user_names[ws]
            puts "Disconnecting a device for #{user_name}"

            @user_names.delete(ws)
            @connections[user_name].reject! { |stored_ws| stored_ws == ws }
          end
        end
      end
    end

    def deliver_history(ws, timestamp)
      user = User.find_by(user_name: @user_names[ws])

      query = user.received_messages

      query = query.where("created_at > ?", timestamp) if !timestamp.nil?

      #it's probably a good idea to limit this query to 20 messages max and make the client paginate via an api request (as i described in a comment above)
      messages = query.desc.limit(20)

      ws.send(messages.map(&:to_json).to_json)
    end

    def deliver_message(recipient_user_name, sender_user_name, msg)
      recipient = User.find_by(user_name: recipient_user_name)
      
      sender = User.find_by(user_name: sender_user_name)

      message = recipient.receive_message(sender, msg)

      @connections[recipient_user_name].each do |recipient_ws|
        recipient_ws.send([message.to_json])
      end
    end

    def connected_devices_count_for(user_name)
      @connections[user_name].count
    end

    def stop
      EM.stop
    end
  end
end
