require 'spec_helper'
require "chattr/server"
require "chattr/client"
require "chattr/message"

describe Chattr::Server do

	it 'allows clients to connect and allows a client to send a message to a user' do
		server = Chattr::Server.new("0.0.0.0", 3001)
		client_1 = Chattr::Client.new("0.0.0.0", 3001, "Dave")
		client_2 = Chattr::Client.new("0.0.0.0", 3001, "Joe")
		client_3 = Chattr::Client.new("0.0.0.0", 3001, "John")

		EM.run do
		 	EM.next_tick do
		 		server.start
		 	end

		 	EM.add_timer(0.25) do
		 		client_1.connect
		 		client_2.connect
		 		client_3.connect
		 	end

		 	EM.add_timer(1) do
		 		client_1.send_message("Joe", "ABCD")
		 	end

			EM.add_timer(1.25) do
				server.stop #stops eventmachine for clients also
				expect(client_2.received_message_count).to eq(1)
				expect(client_1.received_message_count).to eq(0)
				expect(client_3.received_message_count).to eq(0)
			end
		end
	end

	it "allows a client to connect with multiple devices, and both devices should receive a message" do
		server = Chattr::Server.new("0.0.0.0", 3001)
		client_1 = Chattr::Client.new("0.0.0.0", 3001, "Joe")
		client_2 = Chattr::Client.new("0.0.0.0", 3001, "Dave")
		#second device
		client_3 = Chattr::Client.new("0.0.0.0", 3001, "Dave")

		event_thread = Thread.new do
			server.start
			client_1.connect
			client_2.connect
			client_3.connect
		end

		EM.run do
		 	EM.next_tick do
		 		server.start
		 	end

		 	EM.add_timer(0.25) do
		 		client_1.connect
		 		client_2.connect
		 		client_3.connect
		 	end

		 	EM.add_timer(1) do
		 		client_1.send_message("Dave", "ABCD")
		 	end

			EM.add_timer(1.25) do
				server.stop #stops eventmachine for clients also
				expect(client_1.received_message_count).to eq(0)
				expect(client_2.received_message_count).to eq(1)
				expect(client_3.received_message_count).to eq(1)
			end
		end
	end

	it "persists messages" do
		server = Chattr::Server.new("0.0.0.0", 3001)
		client_1 = Chattr::Client.new("0.0.0.0", 3001, "Joe")
		client_2 = Chattr::Client.new("0.0.0.0", 3001, "Dave")

		EM.run do
			EM.next_tick do
				server.start
			end

			EM.add_timer(0.25) do
				client_1.connect
				client_2.connect
			end

			EM.add_timer(1) do
				client_1.send_message("Dave", "ABCD")
			end

			EM.add_timer(1.25) do
				server.stop #stops eventmachine for clients also
				expect(Chattr::Message.count).to eq(1)
			end
		end
	end

	it "allows a client to request all messages from the disconnected period" do
		user = create(:user, :with_received_messages, user_name: "Dave", message_count: 3)

		server = Chattr::Server.new("0.0.0.0", 3001)
		client = Chattr::Client.new("0.0.0.0", 3001, user.user_name) 

		EM.run do
			EM.next_tick do
				server.start
			end

			EM.add_timer(0.25) do
				client.connect
			end

			EM.add_timer(0.5) do
				client.request_history
			end

			EM.add_timer(1.25) do
				server.stop #stops eventmachine for clients also
				expect(client.received_message_count).to eq(3)
			end
		end
	end
end