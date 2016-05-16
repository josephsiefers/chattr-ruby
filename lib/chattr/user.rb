require 'chattr/message'

module Chattr
	class User < ActiveRecord::Base
		has_many :received_messages, foreign_key: :recipient_id, class_name: "Message"
		has_many :sent_messages, foreign_key: :sender_id, class_name: "Message"

		def receive_message(sender, msg)
			received_messages.create(sender: sender, msg: msg)
		end
	end
end