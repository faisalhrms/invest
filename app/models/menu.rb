class Menu < ApplicationRecord
  validates  :name, presence: true, uniqueness: true
  validates  :slug,  uniqueness: true
  has_many  :permissions

  has_many :sub_menus, class_name: "Menu", foreign_key: "main_menu_id", dependent: :destroy
  belongs_to :main_menu, class_name: "Menu", optional: true
end
