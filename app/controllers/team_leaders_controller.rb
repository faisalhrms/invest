class TeamLeadersController < ApplicationController
  before_action :set_team_leader, only: [:update, :destroy]
  before_action :set_countries, only: [:index,:create, :update]
  before_action :set_module_name

  def index
    @can_create = true
    @can_edit = true
    @can_delete = true
    @team_leaders = TeamLeader.all.order(created_at: :desc)
  end

  def create
    @team_leader = TeamLeader.new(team_leader_params)
    if @team_leader.save
      redirect_to team_leader_path, notice: 'Team Leader was successfully created.'
    end
  end


  def update
    if @team_leader.update(team_leader_params)
      redirect_to team_leader_path, notice: 'Team Leader was successfully updated.'
     end
  end

  def destroy
    @team_leader.destroy
    redirect_to team_leader_path, notice: 'Team Leader was successfully deleted.'
  end

  private

  def set_team_leader
    @team_leader = TeamLeader.find(params[:id])
  end

  def set_countries
    @countries = ISO3166::Country.all.map do |country|
      { name: country.translations[I18n.locale.to_s] || country.name, code: country.alpha2, flag: country.emoji_flag }
    end
  end
  def team_leader_params
    params.require(:team_leader).permit(:member_name, :team_members, :country, :date, :investment_amount, :user_capital, :total_earnings)
  end




  def set_module_name
    @module_name = "users"
    @sub_module_name = "team_leaders"

  end
end
