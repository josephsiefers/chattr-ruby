FactoryGirl.define do
	factory :user, class: "Chattr::User" do
		user_name "John"

		transient do
			message_count 3
		end

		trait :with_received_messages do
			after(:create) do |user, evaluator|
				evaluator.message_count.times do
					create(:message, recipient: user)
				end
			end
		end
	end
end