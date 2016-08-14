class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook]

  has_many :groups
  accepts_nested_attributes_for :groups

  def email_required?
  	false
	end

	def email_changed?
  	false
	end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.first_name = auth.info.first_name
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.first_name = session["devise.facebook_data"]["first_name"] if user.first_name.blank?
        user.password = Devise.friendly_token[0,20]
        user.provider = session["devise.facebook_data"]["provider"]
        user.uid = session["devise.facebook_data"]["uid"]
    end
  end
end

end