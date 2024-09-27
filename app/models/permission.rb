class Permission < ApplicationRecord
  belongs_to :role
  belongs_to  :menu


  def self.check_side_bar_permission(menu_name, current_user)
    menu = Menu.find_by(slug: menu_name, is_active: true)
    return false unless menu

    return current_user&.role&.permissions&.exists?(menu_id: menu.id, is_index: true)
  end

  def self.check_permission(menu_name, current_user, permission_type)
    menu = Menu.find_by(slug: menu_name, is_active: true)
    return false unless menu

    return current_user&.role&.permissions&.exists?(menu_id: menu.id, get_permission_column(permission_type) => true)

  end

  def self.get_permission_column(permission_type)
    case permission_type
    when "create"
      :is_create
    when "view"
      :is_view
    when "edit"
      :is_edit
    when "delete"
      :is_delete
    when "index"
      :is_index
    else
      :is_index
    end
  end

end
