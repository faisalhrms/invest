
class Backup < ApplicationRecord

  def self.make_db_bkp
    current_date = Time.now.strftime("%d-%m-%Y")
    system("PGPASSWORD='db_user' pg_dump -F c -v -U db_user -h localhost investment_app -f /home/faisal/Desktop/invest_#{current_date}.sql")
  end
end