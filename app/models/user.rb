class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  has_many :login_histories
  has_many :activity_streams
  has_many :purchases
  belongs_to :role
  has_one_attached :avatar
  has_many :referred_users, class_name: "User", foreign_key: "referred_by"
  belongs_to :referred_by_user, class_name: 'User', foreign_key: 'referred_by', optional: true

  # Method to generate OTP and set its expiry time
  def generate_otp
    self.otp = rand.to_s[2..7]  # 6-digit OTP
    self.otp_expires_at = 15.minutes.from_now
    save!
  end

  # Method to check if OTP is valid
  def otp_valid?(submitted_otp)
    otp == submitted_otp && otp_expires_at > Time.current
  end

  def total_deposit_amount
    purchases.sum(:deposit_amount)
  end
  def total_referrals
    referred_users.count
  end
  # Method to clear OTP after use
  def clear_otp
    self.otp = nil
    self.otp_expires_at = nil
    save!
  end
end
