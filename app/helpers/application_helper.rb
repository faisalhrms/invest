module ApplicationHelper

  def include_all_css_files_from_directory(directory)
    css_files = Dir["#{Rails.root}/app/assets/stylesheets/#{directory}/*.css"].map do |file|
      stylesheet_link_tag "#{directory}/#{File.basename(file, '.css')}", "data-turbo-track": "reload"
    end
    css_files.join.html_safe
  end

  def expanded(action)
    params[:controller] == action ? "false" : "true"
  end

  def is_active(action)
    params[:controller] == action ? "active" : nil
  end
  def link_target_attribute
    current_user&.target ? '_blank' : ''
  end
  def dashboard
    params[:controller] == "dashboards" ? "sidebar-main-active right-column-fixed header-top-bgcolor" : nil
  end

  def include_all_js_files_from_directory(directory)
    js_files = Dir["#{Rails.root}/app/javascript/#{directory}/*.js"].map do |file|
      javascript_include_tag "#{directory}/#{File.basename(file, '.js')}"
    end
    js_files.join.html_safe
  end

  def fetch_permissions(current_user)
    return {} unless current_user

    menus = Menu.where(slug: %w[plans referrals purchases trading_plans staking investment_plans settings dashboard users menus roles activity_streams])
    permissions = Permission.where(role_id: current_user.role_id, menu_id: menus.pluck(:id), is_index: true).pluck(:menu_id)
    permissions_by_menu_slug = menus.index_by(&:slug).slice(*permissions.map { |menu_id| menus.detect { |m| m.id == menu_id }.slug })

    {
      referrals: permissions_by_menu_slug.key?("referrals"),
      purchases: permissions_by_menu_slug.key?("purchases"),
      plans: permissions_by_menu_slug.key?("plans"),
      investment_plans: permissions_by_menu_slug.key?("investment_plans"),
      trading_plans: permissions_by_menu_slug.key?("trading_plans"),
      staking: permissions_by_menu_slug.key?("staking"),
      authentication: permissions_by_menu_slug.key?("settings"),
      dashboard: permissions_by_menu_slug.key?("dashboard"),
      users: permissions_by_menu_slug.key?("users"),
      menus: permissions_by_menu_slug.key?("menus"),
      roles: permissions_by_menu_slug.key?("roles"),
      activity_streams: permissions_by_menu_slug.key?("activity_streams")
    }
  end

  def plan_purchased?(plan)
    case plan.class.name
    when 'InvestmentPlan'
      current_user.purchases.exists?(investment_plan_id: plan.id, approved: true)
    when 'TradingPlan'
      current_user.purchases.exists?(trading_plan_id: plan.id, approved: true)
    when 'Staking'
      current_user.purchases.exists?(staking_id: plan.id, approved: true)
    else
      false
    end
  end

  def purchase_pending?(plan)
    case plan.class.name
    when 'InvestmentPlan'
      current_user.purchases.exists?(investment_plan_id: plan.id, approved: false, status: "pending")
    when 'TradingPlan'
      current_user.purchases.exists?(trading_plan_id: plan.id, approved: false, status: "pending")
    when 'Staking'
      current_user.purchases.exists?(staking_id: plan.id, approved: false, status: "pending")
    else
      false
    end
  end
  def pending_approval_count
    Purchase.where(approved: false, status: "pending").count
  end

end
