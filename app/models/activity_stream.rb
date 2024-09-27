class ActivityStream < ApplicationRecord
  belongs_to  :user

  def self.create_activity_stream(action_name, table_name, table_id, current_user, slug)
    login_histories = current_user.login_histories.where(:is_active => true)
    if login_histories.present?
      ip_address = login_histories.last.ip_address
      browser_name = login_histories.last.browser_name
      user_id = current_user.id
      time = Time.now
      ActivityStream.create(:action_name => action_name, :table_name => table_name, :table_id => table_id, :user_id => user_id, :ip_address => ip_address, :browser_name => browser_name, :action_date => Date.today, :action_datetime => time.strftime("%I:%M:%S %p"), :slug => slug)
    end
  end
end
