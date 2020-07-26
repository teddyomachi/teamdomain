class SpinFileServer < ActiveRecord::Base
  # attr_accessor :title, :body
  
  def self.create_spin_file_server server_info
    s = SpinFileServer.new
    s[:server_name] = server_info[:server_name]
    s[:server_host_name] = server_info[:server_host_name]
    s[:server_protocol] = server_info[:server_protocol]
    s[:server_alt_protocols] = server_info[:server_alt_protocols]
    s[:server_port] = server_info[:server_port]
    s[:root_user] = server_info[:root_user]
    s[:root_password] = server_info[:root_password]
    s[:api_path] = server_info[:api_path]
    s[:updated_at] = server_info[:updated_at]
    # s[:created_at] = server_info[:created_at]
    if s.save
      return s
    else
      return nil
    end
  end # => end of self.create_spin_file_server server_info
  
end
