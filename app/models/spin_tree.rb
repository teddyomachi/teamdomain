require 'tasks/security'

class SpinTree < ActiveRecord::Base
  # attr_accessor :title, :body

  def self.create_spin_tree tree_info
    s = SpinTree.new
    r = Random.new
    s[:spin_tree_hashkey] = Security.hash_key_s tree_info[:spin_tree_name] + r.rand.to_s
    s[:spin_tree_name] = tree_info[:spin_tree_name]
    s[:spin_tree_type] = 'spin_vfs'
    # s[:created_at] = tree_info[:created_at]
    if s.save
      return s
    else
      return nil
    end
  end # => end of self.create_spin_file_server tree_info
  
end
