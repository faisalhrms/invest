class MenusController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]

  def index
    @menus = Menu.all
    create_activity("View Menus Index Page", "Menu", 0)
  end


  def edit_modal
    @menu = Menu.find(params[:id])
    render partial: 'menus/edit_menu_modal', locals: { menu: @menu}
  end


  def create
    if (params[:menu_type] == "sub_menu" and params[:main_menu_id].present?) or (params[:menu_type] == "main_menu")
      menu = Menu.new(menu_params)
      menu.slug = params[:name].gsub(" ", "_").downcase
      if menu.save
        Role.all.each do |role|
          Permission.create(:menu_id => Menu.last.id, :role_id => role.id)
        end
        ActivityStream.create_activity_stream("Create #{Menu.last.name} New Menu", "Menu", Menu.last.id, @current_user, "create")
        flash[:notice] = "User Created Successfully"
      else
        if menu.errors.full_messages.first == "Name has already been taken" or menu.errors.full_messages.first == "Slug has already been taken"
          flash[:alert] = menu.errors.full_messages.first.gsub("Slug", "Name")
        else
          flash[:alert] = "Something Went Wrong"
        end
      end
    else
      flash[:alert] = "Select Main Menu For Sub Menu"
    end
    redirect_to menu_path
  end

  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    menu = Menu.find(params[:id])
    menu.slug = params[:name].gsub(" ", "_").downcase
    if menu.update(menu_params)
      ActivityStream.create_activity_stream("Update #{menu.name} Existing Menu", "Menu", menu.id, @current_user, "edit")
      flash[:notice] = "Menu Updated Successfully"
    else
      if menu.errors.full_messages.first == "Name has already been taken"
        flash[:alert] = menu.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to menu_path
  end

  def destroy
    menu = Menu.find(params[:id])
    if not menu.permissions.present?
      flash[:alert] = "Menu Has Currently Used In Permissions"
    else
      ActivityStream.create_activity_stream("Delete #{menu.name} From Menus", "Menu", menu.id, @current_user, "delete")
      menu.delete
      flash[:notice] = "Menu Deleted"
    end
    redirect_to menu_path
  end

  private

  def menu_params
    params.permit(:name, :is_active, :slug, :menu_type, :main_menu_id)
  end

  def set_module_name
    @module_name = "authentication"
    @sub_module_name = "menus"
  end

end
