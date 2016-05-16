require 'chattr/user'

module Chattr
	class Message < ActiveRecord::Base
		belongs_to :sender, class_name: "User"
		belongs_to :recipient, class_name: "User"

		delegate :user_name, to: :sender, prefix: true
		delegate :user_name, to: :recipient, prefix: true

		scope :desc, ->{ order(created_at: :desc) }

		def to_json
			{ sender_user_name: self.sender_user_name, msg: self.msg, created_at: self.created_at }.to_json
		end
	end
end