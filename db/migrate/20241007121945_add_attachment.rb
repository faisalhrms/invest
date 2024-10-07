class AddAttachment < ActiveRecord::Migration[7.1]
  def change
    add_column :deposits , :attachment_file_name, :string
    add_column :deposits , :attachment_content_type, :string
    add_column :deposits , :attachment_file_size, :integer
    add_column :deposits , :attachment_updated_at, :datetime
    add_column :deposits , :wallet_address, :string
  end
end
