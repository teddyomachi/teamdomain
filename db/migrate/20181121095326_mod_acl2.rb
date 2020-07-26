class ModAcl2 < ActiveRecord::Migration[5.2]
  def change
        change_column :spin_access_controls, :spin_uid_access_right, :integer, :default => -1
        change_column :spin_access_controls, :spin_gid_access_right, :integer, :default => -1
        change_column :spin_access_controls, :spin_world_access_right, :integer, :default => -1
  end
end
