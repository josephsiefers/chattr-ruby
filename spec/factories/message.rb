FactoryGirl.define do
	factory :message, class: "Chattr::Message" do
		recipient { create(:user) }
		sender { create(:user) }
		msg "Some message"
	end
end