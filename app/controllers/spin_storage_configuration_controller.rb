# coding: utf-8
require 'const/stat_const'
require 'tasks/request_broker'
require 'tasks/session_management'
require 'utilities/system'
require 'pg'
require 'pp'

class SpinStorageConfigurationController < ApplicationController
  
  def setup_storages
    #        def self.set_spin_storages ss_server = Vfs::SYSTEM_DEFAULT_SPIN_SERVER, ss_store_name = Vfs::SYSTEM_DEFAULT_STORAGE_NAME, ss_root = Vfs::SYSTEM_DEFAULT_STORAGE_ROOT, ss_vfs = Vfs::SYSTEM_DEFAULT_VFS_NAME, ss_ml = 'LEAST_FILES',ss_max_size = -1,ss_max_ent = -1, ss_max_dirs = -1, ss_max_ent_per_dir = 0, is_default = true, ss_storage_tmp = Vfs::SYSTEM_DEFAULT_TEMP_DIR
    return false if params.blank?
    
    # => parse params
    ss_server = Vfs::SYSTEM_DEFAULT_SPIN_SERVER
    ss_store_name = Vfs::SYSTEM_DEFAULT_STORAGE_NAME
    ss_root = Vfs::SYSTEM_DEFAULT_STORAGE_ROOT
    ss_vfs = Vfs::SYSTEM_DEFAULT_VFS_NAME
    ss_ml = 'LEAST_FILES'
    ss_max_size = -1
    ss_max_ent = -1
    ss_max_dirs = -1
    ss_max_ent_per_dir = 0
    is_default = true
    ss_storage_tmp = Vfs::SYSTEM_DEFAULT_TEMP_DIR
    
    if !params["ss_server"].blank?
      ss_server = params["ss_server"]
    elsif !params["ss_store_name"].blank?
      ss_store_name = params["ss_store_name"]
    elsif !params["ss_root"].blank?
      ss_root = params["ss_root"]
    elsif !params["ss_vfs"].blank?
      ss_vfs = params["ss_vfs"]
    elsif !params["ss_ml"].blank?
      ss_ml = params["ss_ml"]
    elsif !params["ss_max_size"].blank?
      ss_max_size = params["ss_max_size"]
    elsif !params["ss_max_ent"].blank?
      ss_max_ent = params["ss_max_ent"]
    elsif !params["ss_max_dirs"].blank?
      ss_max_dirs = params["ss_max_dirs"]
    elsif !params["ss_max_ent_per_dir"].blank?
      ss_max_ent_per_dir = params["ss_max_ent_per_dir"]
    elsif !params["is_default"].blank?
      is_default = params["is_default"]
    elsif !params["ss_storage_tmp"].blank?
      ss_storage_tmp = params["ss_storage_tmp"]
    end # => end of parse
    
    # => call set_spin_storages
    SystemTools::DbTools.set_spin_storages(ss_server, ss_store_name, ss_root, ss_vfs, ss_ml, ss_max_size, ss_max_ent, ss_max_dirs, ss_max_ent_per_dir, is_default, ss_storage_tmp)
    
  end
end
