module RolesHelper

  def fetch_permissions_for_submodule(sub_module_name, user)
    {
      can_create: Permission.check_permission(sub_module_name, user, "create"),
      can_edit: Permission.check_permission(sub_module_name, user, "edit"),
      can_delete: Permission.check_permission(sub_module_name, user, "delete")
    }
  end

end
