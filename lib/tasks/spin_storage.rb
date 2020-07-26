# coding: utf-8

module Spinstorage
  def initializer
    @storage_logic = {
      :name => 'POSIX_LOGIC_0',         # => default logic name
      :type => 'POSIX',                 # => { POSIX, WOS, DVD, NTFS, IFS }
      :max_width => 10000,
      :max_depth => 10000,
      :number_of_objects => 1000,       # => numbere of  object in directory
      :number_of_directories => 1000    # => number of directories in the same depth 
    }
    @storage_params = {
      :max_size => 1000000,              # => size unit GB
      :storage_type => 'XFS',            # => { XFS, NFS, WOS}
      :storage_server => 'local',        # => default LOCAL STORAGE vakues are { local, servername, server address }
      :storage_path => '/usr/local/secret_files/storage/POSIX_LOGIC_0',
      :security => 'normal',
      :replication => false,
      :warning_threshold => 80.0         # => warn if the usage exceeds N'%'
    }
  end
  def set_logic( logic )
    logic.each do |k,v|
      @storage_logic[k] = v
    end
    return @storage_logic
  end
  def get_logic
    
  end
end