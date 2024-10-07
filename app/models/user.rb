class User < ApplicationRecord
  has_secure_password
  validates :email, presence: { message: "Email is required" }, uniqueness: { message: "This email is already taken" }
  has_many :login_histories
  has_many :activity_streams
  has_many :purchases
  belongs_to :role
  has_one_attached :avatar
  has_many :withdrawals, dependent: :destroy
  has_many :referral_commissions
  has_many :deposits, dependent: :destroy
  # Self-referencing associations for referrals
  has_many :referred_users, class_name: "User", foreign_key: "referred_by"
  belongs_to :referred_by_user, class_name: 'User', foreign_key: 'referred_by', optional: true
  belongs_to :rank, optional: true
  has_many :transaction_histories
  after_create :calculate_initial_referral_commission
  validates :mobile_with_country_code, presence: { message: "Mobile number is required" },
            uniqueness: { message: "This mobile number is already registered" },
            unless: -> { user_type == "administrator" }

  validates :user_name, presence: { message: "Username is required" },
            uniqueness: { message: "This username is already taken" },
            unless: -> { user_type == "administrator" }

  before_save :downcase_email


  def generate_otp
    self.otp = rand.to_s[2..7]  # 6-digit OTP
    self.otp_expires_at = 15.minutes.from_now
    save!
  end

  # Assign rank based on the user's total deposit amount
  def assign_rank
    self.rank = Rank.where('minimum_deposit <= ?', total_deposit_amount).order(minimum_deposit: :desc).first
    save!
  end

  # Calculate daily profit based on the user's rank and total deposit
  def daily_profit
    return 0 unless rank.present?
    (total_deposit_amount * rank.profit_percentage) / 100.0
  end

  # Calculate the total deposit amount for the user
  def total_deposit_amount
    purchases.where(approved: true, status: "active").sum(:deposit_amount)
  end

  # Calculate the total deposit amount for all referred users
  def refer_deposit_amount
    referred_users.joins(:purchases).where(purchases: { approved: true, status: "active" }).sum(:deposit_amount)
  end

  # Calculate total referrals
  def total_referrals
    referred_users.count
  end

  def update_cumulative_profit!
    return if last_profit_calculation == Date.today

    purchases.where(approved: true, status: "active").each do |purchase|
      purchase.calculate_profit
    end

    self.total_profit = purchases.joins(:profit).sum("profits.amount")

    self.last_profit_calculation = Date.today
    save!
  end
  def calculate_initial_referral_commission


    return unless referred_by_user.present?

    referral_commission_amount = 100.0

    # Create the referral commission record
    referral_commission = ReferralCommission.create!(
      user: referred_by_user,
      referral_user_id: id,
      amount: referral_commission_amount,
    )

    # Create a deposit entry for the referring user
    deposit = Deposit.create!(
      user_id: referred_by_user.id,
      amount: referral_commission_amount,
      status: 'referral_commission',
      processed_at: Time.current,
    )

    # Add transaction history for the referral commission
    TransactionHistory.create!(
      user: referred_by_user,
      amount: referral_commission_amount,
      transaction_type: "Referral Commission",
      status: 'active',
      referral_commission_id: referral_commission.id,
      deposit_id: deposit.id
    )
  end

  def otp_valid?(submitted_otp)
    otp == submitted_otp && otp_expires_at > Time.current
  end

  def profit_visible?
    # If the user has any active purchases, check if the profit is eligible
    profit_eligible?
  end
  def clear_otp
    self.otp = nil
    self.otp_expires_at = nil
    save!
  end


  def commission_rate
    5.0  # Default to 5% commission
  end
  def calculate_referral_commission(purchase_amount)
    (purchase_amount * commission_rate) / 100.0
  end
  def total_referral_commissions
    referral_commissions.sum(:amount)
  end
  def eligible_profit
    return 0 unless profit_eligible?
    total_profit - total_profit_withdrawn
  end

  def profit_eligible?
    return false if purchases.empty?

    # Check if any active purchase is more than 30 days old
    purchases.where(approved: true, status: "active").any? do |purchase|
      (Date.today - purchase.created_at.to_date).to_i >= 30
    end
  end

  def total_referral_commission
    referral_commissions.sum(:amount)
  end
  def withdrawable_referral_commission
    total_referral_commission
  end
  # Track total profit withdrawn
  def total_profit_withdrawn
    withdrawals.where(withdrawal_type: 'profit', status: 'approved').sum(:amount)
  end

  def total_referral_withdrawn
    withdrawals.where(withdrawal_type: 'referral', status: 'approved').sum(:amount)
  end

  def total_deposits
    deposits.where.not(status: ['used for purchase','invalid']).sum(:amount)
  end

  def total_withdrawable_profit
    deposits.where(profit_eligible: true).sum(:calculated_profit)
  end
  def total_withdrawable_amount
    total_deposits + total_withdrawable_profit + withdrawable_referral_commission
  end


  def withdrawal_count_by_plan_type(plan_type)
    case plan_type
    when 'investment_plan'
      withdrawals.where(status: 'approved', investment_plan_id: purchases.select(:investment_plan_id).distinct).count
    when 'trading_plan'
      withdrawals.where(status: 'approved', trading_plan_id: purchases.select(:trading_plan_id).distinct).count
    when 'staking'
      withdrawals.where(status: 'approved', staking_id: purchases.select(:staking_id).distinct).count
    else
      0
    end
  end

  def total_purchase_amount_by_plan_type(plan_type)
    plan_column = case plan_type
                  when 'investment_plan'
                    :investment_plan_id
                  when 'trading_plan'
                    :trading_plan_id
                  when 'staking'
                    :staking_id
                  else
                    return 0
                  end

    purchases.where(approved: true, status: "active").where.not(plan_column => nil).sum(:deposit_amount)
  end
  def total_profit_by_plan_type(plan_type)
    plan_column = case plan_type
                  when 'investment_plan'
                    :investment_plan_id
                  when 'trading_plan'
                    :trading_plan_id
                  when 'staking'
                    :staking_id
                  else
                    return 0
                  end

    # Apply 31-day logic only for trading and staking plans
    if plan_type == 'trading_plan' || plan_type == 'staking'
      purchases
        .joins(:profit)
        .where(approved: true, status: "active")
        .where.not(plan_column => nil)
        .where("#{plan_column} IS NOT NULL AND DATE_PART('day', NOW() - purchases.created_at) >= 31")
        .sum("profits.amount")
    else
      # For investment plans, calculate the profit without 31-day restriction
      purchases
        .joins(:profit)
        .where(approved: true, status: "active")
        .where.not(plan_column => nil)
        .sum("profits.amount")
    end
  end


  def create_transaction_history(purchase, transaction_type, amount, profit_loss_type)
    plan_id = determine_plan_id(purchase)
    status = profit_loss_type == 'profit' ? 'profit_applied' : 'loss_applied'

    # Create a new transaction history record for the profit/loss adjustment
    TransactionHistory.create_transaction(
      purchase.user,
      amount,
      transaction_type,
      nil,
      plan_id,
      status,
      purchase.id
    )
  end

  def apply_manual_profit_or_loss(plan_type, percentage, profit_loss_type)
    purchases_to_update = purchases.where(approved: true, status: 'active').where("#{plan_type}_id IS NOT NULL")

    purchases_to_update.each do |purchase|
      current_profit = purchase.profit || Profit.new(user: self, purchase: purchase)

      adjustment_amount = (purchase.deposit_amount * percentage) / 100.0
      adjustment_amount *= -1 if profit_loss_type == 'loss'

      if current_profit.persisted?
        current_profit.update(amount: current_profit.amount + adjustment_amount)
      else
        current_profit.amount = adjustment_amount
        current_profit.save!
      end

      create_transaction_history(purchase, "#{profit_loss_type}_adjustment", adjustment_amount, profit_loss_type)
    end
  end

  def determine_plan_id(purchase)
    if purchase.investment_plan_id.present?
      purchase.investment_plan_id
    elsif purchase.trading_plan_id.present?
      purchase.trading_plan_id
    elsif purchase.staking_id.present?
      purchase.staking_id
    end
  end

  def total_referral_profit_sum
    referred_users.sum(:total_profit)
  end

  def adjusted_total_profit
    # For Trading and Staking plans: Show profit only if purchase is older than 31 days
    trading_and_staking_profit = purchases
                                   .where(approved: true, status: 'active')
                                   .where.not(trading_plan_id: nil).or(purchases.where.not(staking_id: nil))
                                   .select { |purchase| (Date.today - purchase.created_at.to_date).to_i >= 31 }
                                   .sum { |purchase| purchase.profit.try(:amount).to_f }

    # For Investment plans: Show daily profit without date restriction
    investment_profit = purchases
                          .where(approved: true, status: 'active', investment_plan_id: investment_plan_ids)
                          .sum { |purchase| purchase.profit.try(:amount).to_f }

    # Combine the profits from both types
    trading_and_staking_profit + investment_profit
  end

  def displayed_profit(filter = 'total')
    case filter
    when 'total'
      adjusted_total_profit
    when 'this_month'
      this_month_profit
    when 'last_month'
      last_month_profit
    else
      adjusted_total_profit
    end
  end

  def this_month_profit
    purchases.joins(:profit)
             .where(approved: true, status: 'active')
             .where('profits.created_at >= ? AND profits.created_at <= ?', Time.current.beginning_of_month, Time.current.end_of_month)
             .sum('profits.amount')
  end

  # Calculate the total profit for last month
  def last_month_profit
    purchases.joins(:profit)
             .where(approved: true, status: 'active')
             .where('profits.created_at >= ? AND profits.created_at <= ?', Time.current.last_month.beginning_of_month, Time.current.last_month.end_of_month)
             .sum('profits.amount')
  end

  private
  def downcase_email
    self.email = email.downcase
  end
  def investment_plan_ids
    purchases.where.not(investment_plan_id: nil).pluck(:investment_plan_id).uniq
  end
end
