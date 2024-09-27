class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]

  def index
    @roles = Role.all
    @menus = Menu.includes(:sub_menus).where(menu_type: "main_menu").distinct
    create_activity("View Role/Permissions Index Page", "Role", 0)
  end

  def edit_modal
    @role = Role.find(params[:id])
    @menus = Menu.includes(:sub_menus).where(menu_type: "main_menu").distinct
    render partial: 'roles/edit_role_modal', locals: { role: @role }
  end


  def show
    if params[:is_active].present?
      params[:is_active] = true
    else
      params[:is_active] = false
    end
    @roles = Role.where(:is_active => params[:is_active])
    if @roles.present?
      ActivityStream.create_activity_stream("Filter Roles/Permissions", "Role", 0, @current_user, "filter")
      flash[:notice] = "Role Found Successfully"
    else
      flash[:alert] = "No Record Found"
    end
    render 'roles/index'
  end

  def create
    role = Role.new(role_params)
    if role.save
      role_id = Role.last.id
      params[:menu_id].each_with_index do |menu_id, index|
        check_prev_permission = Permission.where(:role_id => role_id, :menu_id => menu_id.to_i)
        menu = Menu.find(menu_id)
        if check_prev_permission.present?
          if menu.menu_type == "sub_menu"
            check_prev_permission.update(:is_index => params[:is_index][index], :is_create => params[:is_create][index], :is_view => params[:is_view][index], :is_edit => params[:is_edit][index], :is_delete => params[:is_delete][index])
          else
            check_prev_permission.update(:is_index => params[:is_index][index])
          end
        else
          if menu.menu_type == "sub_menu"
            permission = Permission.new
            permission.role_id = role_id
            permission.menu_id = menu_id.to_i
            permission.is_index = params[:is_index][index]
            permission.is_create = params[:is_create][index]
            permission.is_view = params[:is_view][index]
            permission.is_edit = params[:is_edit][index]
            permission.is_delete = params[:is_delete][index]
            permission.save
          else
            permission = Permission.new
            permission.role_id = role_id
            permission.menu_id = menu_id.to_i
            permission.is_index = params[:is_index][index]
            permission.save
          end
        end
      end
      ActivityStream.create_activity_stream("Create #{Role.last.name} New Role/Permissions", "Role", Role.last.id, @current_user, "create")
      flash[:notice] = "Role Created Successfully"
    else
      if role.errors.full_messages.first == "Name has already been taken"
        flash[:alert] = role.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to role_path
  end

  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    role = Role.find(params[:role_id])
    if role.update(role_params)
      params[:permission_ids].each_with_index do |permission_id, index|
        permission = Permission.find(permission_id)
        permission.update(:is_index => params[:is_index][index], :is_create => params[:is_create][index], :is_view => params[:is_view][index], :is_edit => params[:is_edit][index], :is_delete => params[:is_delete][index])
      end
      ActivityStream.create_activity_stream("Update #{role.name} Existing Role/Permissions", "Role", role.id, @current_user, "edit")
      flash[:notice] = "Role/Permissions Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to role_path
  end

  def destroy
    role = Role.find(params[:id])
    if role.users.present?
      flash[:alert] = "Role Has Currently Assigned To Users"
    else
      ActivityStream.create_activity_stream("Delete #{role.name} From Roles/Permissions", "Role", role.id, @current_user, "delete")
      role.permissions.delete_all
      role.delete
      flash[:notice] = "Role/Permission Deleted"
    end
    redirect_to role_path
  end

  private

  def role_params
    params.permit(:name, :is_active)
  end

  def set_module_name
    @module_name = "authentication"
    @sub_module_name = "roles"
  end

end
