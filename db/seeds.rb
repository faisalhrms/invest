["dashboard", "settings", "activity_streams"].each do |main_menu|
  check_menu = Menu.where(:slug => main_menu)
  if not check_menu.present?
    if main_menu == "dashboard" or main_menu == "activity_streams"
      Menu.create(:name => main_menu.gsub("_", " ").capitalize, :menu_type => "main_menu", :is_active => true, :slug => main_menu)
    elsif main_menu == "settings"
      Menu.create(:name => main_menu.gsub("_", " ").capitalize, :menu_type => "main_menu", :is_active => true, :slug => main_menu)
      ["users", "menus", "roles"].each do |sub_menu|
        main_menu_id = Menu.where(:slug => main_menu).last.id
        check_sub_menu = Menu.where(:slug => sub_menu)
        if not check_sub_menu.present?
          Menu.create(:name => sub_menu.gsub("_", " ").capitalize, :menu_type => "sub_menu", :is_active => true, :slug => sub_menu, :main_menu_id => main_menu_id)
        end
      end
    end
  else
    if main_menu == "settings"
      ["users", "menus", "roles"].each do |sub_menu|
        main_menu_id = Menu.where(:slug => main_menu).last.id
        check_sub_menu = Menu.where(:slug => sub_menu)
        if not check_sub_menu.present?
          Menu.create(:name => sub_menu.gsub("_", " ").capitalize, :menu_type => "sub_menu", :is_active => true, :slug => sub_menu, :main_menu_id => main_menu_id)
        end
      end
    end
  end
end
puts "Menus Created"

check_role = Role.where(:name => "Administrator")
if check_role.present?
  role = check_role.last
else
  role = Role.create(:is_active => true, :name => "Administrator")
end
puts "Role Created"

Menu.all.each do |menu|
  check_prev_permission = Permission.where(:role_id => role.id, :menu_id => menu.id)
  if check_prev_permission.present?
    if menu.menu_type == "sub_menu"
      check_prev_permission.update(:is_index => true, :is_create => true, :is_view => true, :is_edit => true, :is_delete => true)
    else
      check_prev_permission.update(:is_index => true)
    end
  else
    if menu.menu_type == "sub_menu"
      permission = Permission.new
      permission.role_id = role.id
      permission.menu_id = menu.id.to_i
      permission.is_index = true
      permission.is_create = true
      permission.is_view = true
      permission.is_edit = true
      permission.is_delete = true
      permission.save
    else
      permission = Permission.new
      permission.role_id = role.id
      permission.menu_id = menu.id.to_i
      permission.is_index = true
      permission.save
    end
  end
end
puts "Permissions Created"

check_user = User.where(:email => "admin@support.com")
if check_user.present?
  check_user.update(:role_id => role.id, :is_active => true, :is_logged_in => false)
else
  User.create(:email => "admin@support.com", :password => "Admin@123", :full_name => "Administrator", :is_active => true, :is_logged_in => false, :role_id => role.id, :user_type => "administrator")
end
puts "Admin User Created"
