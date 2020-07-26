class FolderMigration < ActiveRecord::Migration[5.2]
  def change
	add_column :folder_data, :is_domain_root, :boolean, :default=>false
  end
end
