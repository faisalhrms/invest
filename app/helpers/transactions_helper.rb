# app/helpers/transactions_helper.rb
module TransactionsHelper
  def icon_class_for(transaction_type)
    case transaction_type.downcase
    when "cancel plan"
      "bg-warning"
    when "plan purchased"
      "bg-success"
    when "refund"
      "bg-primary"
    when "withdraw"
      "bg-danger"
    else
      "bg-secondary"
    end
  end

  def icon_for(transaction_type)
    case transaction_type.downcase
    when "cancel plan"
      '<i class="ri-qr-scan-line"></i>'.html_safe
    when "plan purchased"
      '<i class="ri-bar-chart-grouped-fill"></i>'.html_safe
    when "refund"
      '<i class="ri-arrow-go-back-fill"></i>'.html_safe
    when "withdraw"
      '<i class="ri-money-dollar-circle-line"></i>'.html_safe
    else
      '<i class="ri-refresh-line"></i>'.html_safe
    end
  end
end
