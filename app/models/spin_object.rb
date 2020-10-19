# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'

class SpinObject < ActiveRecord::Base
  include Vfs
  
  attr_accessor :date_created, :date_modified, :node_type, :node_version, :node_x_coord, :node_x_pr_coord, :node_y_coord, :object_attributes, :object_name, :src_attributes, :src_platform
  
  def self.get_object_name_by_key node_key
    obj = self.find_by_node_hashkey node_key
    if obj
      return obj[:object_name]
    else
      return nil
    end
  end # => end of get_object_name_by_key
  
  def self.get_object_name node_key
    obj = self.find_by_node_hashkey node_key
    return obj[:object_name]
  end # => end of get_object_name_by_key
  
end
