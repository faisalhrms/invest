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
    current_rank = rank
    total_approved_amount = purchases.where(approved: true, status: "active").sum(:deposit_amount)
    self.rank = Rank.where('minimum_deposit <= ?', total_approved_amount).order(minimum_deposit: :desc).first
    if self.rank != current_rank
      self.new_rank_assigned = true
    else
      self.new_rank_assigned = false
    end
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

  def total_referrals
    referred_users.count
  end

  def update_cumulative_profit!
    return if last_profit_calculation == Date.today

    ActiveRecord::Base.transaction do
      purchases.where(approved: true, status: "active").find_each do |purchase|
        purchase.calculate_profit
      end

      self.total_profit = purchases.joins(:profit).sum("profits.amount")
      self.last_profit_calculation = Date.today
      save!
    end
  end



  def create_referral_commission_for_purchase(purchase)
    return unless referred_by_user.present?

    # Get the commission rate from the associated plan
    commission_rate = find_commission_rate_for_purchase(purchase)

    if commission_rate.nil? || commission_rate <= 0
      raise "Commission rate is not defined or is zero for the associated plan. Please set a valid commission rate."
    end
    # Calculate the referral commission amount based on the plan's commission rate
    referral_commission_amount = (purchase.deposit_amount * commission_rate) / 100.0

    # Create the referral commission record
    referral_commission = ReferralCommission.create!(
      user: referred_by_user,
      referral_user_id: id,
      amount: referral_commission_amount,
      purchase_id: purchase.id  # Link commission to the specific purchase
    )

    # Create a deposit entry for the referring user
    deposit = Deposit.create!(
      user_id: referred_by_user.id,
      amount: referral_commission_amount,
      status: 'referral_commission',
      processed_at: Time.current
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
    deposits.where(status: ['referral_commission']).sum(:amount)
  end
  # Track total profit withdrawn
  def total_profit_withdrawn
    withdrawals.where(withdrawal_type: 'profit', status: 'approved').sum(:amount)
  end

  def total_referral_withdrawn
    withdrawals.where(withdrawal_type: 'referral', status: 'approved').sum(:amount)
  end

  def total_deposits
    deposits.where.not(status: ['used for purchase','invalid','pending','referral_commission']).sum(:amount)
  end

  def total_withdrawable_profit
    purchases
      .joins(:profit)
      .where(approved: true, status: 'active')
      .where('DATE_PART(\'day\', NOW() - purchases.approve_at) >= 31') # Ensure 31 days have passed since approval
      .sum('profits.amount')
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

  def daily_profit_by_plan_type(plan_type)
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

    # Calculate daily profit based on the active purchases for the specified plan type
    purchases
      .where(approved: true, status: 'active')
      .where.not(plan_column => nil)
      .sum do |purchase|
      plan = case plan_type
             when 'investment_plan'
               purchase.investment_plan
             when 'trading_plan'
               purchase.trading_plan
             when 'staking'
               purchase.staking
             else
               nil
             end
      next 0 unless plan.present?

      # Get the profit percentage from the plan
      profit_percentage = plan.profit_percentage || 0.0

      # Calculate the duration of the plan, handling staking duration differently
      plan_duration = if plan_type == 'staking'
                        purchase.duration_in_days  # Get duration from purchase for staking
                      else
                        plan.duration_in_days  # Use plan's duration for investment/trading
                      end
      next 0 unless plan_duration.present? && plan_duration > 0

      # Calculate total and daily profit
      total_profit = (purchase.deposit_amount * profit_percentage / 100.0) * (plan_duration.to_f / 31)
      daily_profit = total_profit / plan_duration

      # Calculate days since the plan was approved
      days_since_approval = (Date.today - purchase.approve_at.to_date).to_i
      next 0 if days_since_approval <= 0

      # Calculate the accumulated profit based on the number of days passed
      accumulated_profit = [days_since_approval, plan_duration].min * daily_profit

      # If no profit record exists, return the calculated profit
      if purchase.profit.nil?
        accumulated_profit
      else
        # If profit exists, check its type
        if purchase.profit.profit_loss_type == 'loss'
          -purchase.profit.amount.abs  # Show the loss as a negative amount
        elsif purchase.profit.profit_loss_type == 'profit'
          purchase.profit.amount  # Show the profit as a positive amount
        else
          accumulated_profit  # Default to calculated profit if no valid profit/loss type
        end
      end
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
      current_profit = purchase.profit || Profit.new(user: self, purchase: purchase, profit_loss_type: profit_loss_type)

      plan_price = case plan_type
                   when 'trading_plan'
                     purchase.trading_plan&.price || 0
                   when 'staking'
                     purchase.staking&.price || 0
                   else
                     0
                   end

      adjustment_amount = (purchase.deposit_amount + current_profit.amount * percentage) / 100.0
      adjustment_amount *= -1 if profit_loss_type == 'loss'  # Make it negative if it's a loss

      if profit_loss_type == 'loss' && (current_profit.amount.nil? || current_profit.amount.zero?)
        adjusted_deposit_amount = purchase.deposit_amount.to_f + adjustment_amount

        if adjusted_deposit_amount < plan_price
          purchase.update!(approved: false, status: 'inactive', deposit_amount: adjusted_deposit_amount)
          create_transaction_history(purchase, "Deactivated due to insufficient funds (#{adjustment_amount})", adjustment_amount, profit_loss_type)
          refund_amount = adjusted_deposit_amount
          Deposit.create!(
            user_id: purchase.user_id,
            amount: refund_amount,
            processed_at: Time.current,
            status: "refund",
            investment_plan_id: purchase.investment_plan_id,
            trading_plan_id: purchase.trading_plan_id,
            staking_id: purchase.staking_id,
            calculated_profit: 0.0,
            profit_eligible: false
          )
        else
          purchase.update!(deposit_amount: adjusted_deposit_amount)
          create_transaction_history(purchase, "Deposit #{profit_loss_type}_adjustment (#{adjustment_amount})", adjustment_amount, profit_loss_type)
        end
      else
        if current_profit.persisted?
          current_profit.update(amount: current_profit.amount + adjustment_amount, profit_loss_type: profit_loss_type)
        else
          current_profit.amount = adjustment_amount
          current_profit.profit_loss_type = profit_loss_type
          current_profit.save!
        end
        create_transaction_history(purchase, "#{profit_loss_type}_adjustment", adjustment_amount, profit_loss_type)
      end
    end
  rescue ArgumentError => e
    puts "Error: #{e.message}"
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

  def monthly_profit_by_plan_type(plan_type)
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

    # Apply 31-day restriction for all plan types, including investment_plan
    purchases
      .joins(:profit)
      .where(approved: true, status: 'active')
      .where.not(plan_column => nil)
      .where('DATE_PART(\'day\', NOW() - purchases.created_at) >= 31') # Apply 31-day restriction to all plans
      .sum('profits.amount')
  end

  def displayed_profit(plan_type = 'total', filter = 'total')
    case plan_type
    when 'investment_plan'
      monthly_profit_by_plan_type('investment_plan')
    when 'trading_plan'
      monthly_profit_by_plan_type('trading_plan')
    when 'staking'
      monthly_profit_by_plan_type('staking')
    when 'total'
      # Sum up profits from all plans
      monthly_profit_by_plan_type('investment_plan') +
        monthly_profit_by_plan_type('trading_plan') +
        monthly_profit_by_plan_type('staking')
    when 'this_month'
      this_month_profit
    when 'last_month'
      last_month_profit
    else
      # Return total if no specific plan type is requested
      monthly_profit_by_plan_type('investment_plan') +
        monthly_profit_by_plan_type('trading_plan') +
        monthly_profit_by_plan_type('staking')
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
  def investment_plan_ids
    purchases.where.not(investment_plan_id: nil).pluck(:investment_plan_id).uniq
  end
  def trading_plan_ids
    purchases.where.not(trading_plan_id: nil).pluck(:trading_plan_id).uniq
  end

  def staking_ids
    purchases.where.not(staking_id: nil).pluck(:staking_id).uniq
  end
  private
  def downcase_email
    self.email = email.downcase
  end

  def find_commission_rate_for_purchase(purchase)
    if purchase.investment_plan.present?
      purchase.investment_plan.commission_rate
    elsif purchase.trading_plan.present?
      purchase.trading_plan.commission_rate
    elsif purchase.staking.present?
      purchase.staking.commission_rate
    else
      nil  # Return nil if no valid plan is associated
    end
  end


  def daily_profits_by_plan_type(plan_type)
    plan_column = case plan_type
                  when 'investment_plan'
                    :investment_plan_id
                  when 'trading_plan'
                    :trading_plan_id
                  when 'staking'
                    :staking_id
                  else
                    return []
                  end

    profits = purchases
                .where(approved: true, status: 'active')
                .where.not(plan_column => nil)
                .joins(:profit)
                .select('profits.*, purchases.id as purchase_id')
                .order('profits.created_at ASC')

    if plan_type == 'investment_plan'
      # Calculate cumulative profit per day
      daily_profits = profits.group_by { |p| p.created_at.to_date }.map do |date, profits_on_date|
        total = profits_on_date.sum(&:amount)
        { date: date, amount: total }
      end
    else
      # For trading and staking plans, include profit or loss type
      daily_profits = profits.map do |profit|
        {
          date: profit.created_at.to_date,
          amount: profit.amount,
          profit_loss_type: profit.profit_loss_type,
          purchase_id: profit.purchase_id
        }
      end
    end

    daily_profits
  end



end
