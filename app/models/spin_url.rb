# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'utilities/image_utilities'

class SpinUrl < ActiveRecord::Base
  include Vfs
  include Acl
  include Stat

  # attr_accessor :title, :body

  def self.generate_ephemeral_url sid, open_file_key, open_file_name, expires_after = EXPIRE_100_YEARS_AFTER, server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    rsa_key_pem = SpinNode.get_root_rsa_key
    pdata = sid + open_file_key + open_file_name
    # make encrypted data
    file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata

    # basew64 url safe encoding
    fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])

    my_server_params = SpinFileServer.find_by_server_port server_port
    my_spin_url = my_server_params[:spin_url_server_name] + SYSTEM_DEFAULT_URL_DOWNLOADER + '/' + fmargs

    return my_spin_url
  end

  # => end of self.generate_url node_key, expires_at = EXPIRE_100_YEARS_AFTER

  # generates permanent URL
  def self.generate_url sid, open_file_key, open_file_name, spin_node_type = NODE_FILE, disp_file_key = '', expires_after = EXPIRE_100_YEARS_AFTER, server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    # get node
    url_node = SpinNode.find_by_spin_node_hashkey(open_file_key)
    if url_node.blank?
      return nil
    end

    if spin_node_type == NODE_THUMBNAIL or spin_node_type == NODE_PROXY_MOVIE
      thumbnail_info = SpinLocationManager.get_thumbnail_info(sid, open_file_key)
      if thumbnail_info.blank?
        return nil
      end
      thumbnail_path = thumbnail_info[:thumbnail_path]
      if thumbnail_path.blank?
        return nil
      end
      unless File::exist?(thumbnail_path)
        return nil
      end
      # check tuhmbnail_path
    end

    # get uid, gid
    ids = SessionManager.get_uid_gid(sid, true)

    url_pos = {}
    url_pos[:X] = url_node[:node_x_coord]
    url_pos[:Y] = url_node[:node_y_coord]
    url_pos[:PRX] = url_node[:node_x_pr_coord]
    url_pos[:V] = url_node[:node_version]
    url_pos[:K] = open_file_key
    url_pos[:T] = spin_node_type
    url_pos[:EXP] = Time.now + expires_after
    url_pos[:VTREE] = url_node[:spin_tree_type]
    url_pos[:PUID] = ids[:uid]
    url_pos[:PGID] = ids[:gid]

    # get rsa key of the root of the tree to which url_node belongs
    rsa_key_pem = SpinNode.get_root_rsa_key
    pdata = sid + url_pos.to_json
    #    FileManager.rails_logger("generate_url pdata = [" + pdata + "]")

    # make encrypted data
    file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata

    # basew64 url safe encoding
    fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])

    my_server_params = SpinFileServer.find_by_server_port SYSTEM_DEFAULT_SPIN_FILE_MANAGER_PORT
    my_spin_url = String.new
    if my_server_params.present?
      my_spin_url = my_server_params[:spin_url_server_name] + SYSTEM_DEFAULT_URL_DOWNLOADER + '/' + fmargs
    else
      my_spin_url = SYSTEM_DEFAULT_URL_SERVER + SYSTEM_DEFAULT_URL_DOWNLOADER + '/' + fmargs
    end

    # search spin_urls node
    url_rec = self.find_by_nx_and_ny_and_nv(url_pos[X], url_pos[Y], url_pos[V])

    catch(:generate_url_again) {

      self.transaction do

        begin
          if url_rec.blank?
            url_rec = self.new {|url_rec|
              url_rec[:nx] = url_node[:node_x_coord]
              url_rec[:ny] = url_node[:node_y_coord]
              url_rec[:nprx] = url_node[:node_x_pr_coord]
              url_rec[:nv] = url_node[:node_version]
              url_rec[:nt] = spin_node_type
              url_rec[:spin_url] = my_spin_url
              url_rec[:spin_node_name] = open_file_name
              url_rec[:spin_node_hashkey] = open_file_key
              url_rec[:generator_session] = sid
              url_rec[:hash_key] = disp_file_key.empty? ? sid : disp_file_key
            }
          else
            url_rec[:nx] = url_node[:node_x_coord]
            url_rec[:ny] = url_node[:node_y_coord]
            url_rec[:nprx] = url_node[:node_x_pr_coord]
            url_rec[:nv] = url_node[:node_version]
            url_rec[:nt] = spin_node_type
            url_rec[:spin_url] = my_spin_url
            url_rec[:spin_node_name] = open_file_name
            url_rec[:spin_node_hashkey] = open_file_key
            url_rec[:generator_session] = sid
            url_rec[:hash_key] = disp_file_key.empty? ? sid : disp_file_key
          end
          url_rec.save
          return my_spin_url
        rescue ActiveRecord::StaleObjectError
          return nil
        end
      end
    }

  end

  # => end of self.generate_url node_key, expires_at = EXPIRE_100_YEARS_AFTER

  # generates permanent URL
  def self.generate_public_url sid, open_file_key, open_file_name, spin_node_type = NODE_FILE, expires_after = EXPIRE_100_YEARS_AFTER, server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    # get node
    url_node = SpinNode.find_by_spin_node_hashkey(open_file_key)
    #    loc_node = SpinLocationMapping.find_by_node_hash_key(open_file_key)

    #    if loc_node == nil
    #      return ''
    #    end

    if spin_node_type == NODE_THUMBNAIL or spin_node_type == NODE_PROXY_MOVIE
      thumbnail_info = SpinLocationManager.get_thumbnail_info(sid, open_file_key)
      thumbnail_path = thumbnail_info[:thumbnail_path]
      if thumbnail_path.empty?
        return ''
      end
      unless File::exist?(thumbnail_path)
        return ''
      end
      # check tuhmbnail_path
    end

    # get uid, gid
    ids = SessionManager.get_uid_gid(sid, true)

    url_pos = {}
    url_pos[:X] = url_node[:node_x_coord]
    url_pos[:Y] = url_node[:node_y_coord]
    url_pos[:PRX] = url_node[:node_x_pr_coord]
    url_pos[:V] = url_node[:node_version]
    url_pos[:K] = open_file_key
    url_pos[:T] = spin_node_type
    url_pos[:EXP] = Time.now + expires_after
    url_pos[:VTREE] = url_node[:spin_tree_type]
    url_pos[:PUID] = ids[:uid]
    url_pos[:PGID] = ids[:gid]

    # get rsa key of the root of the tree to which url_node belongs
    rsa_key_pem = SpinNode.get_root_rsa_key
    pdata = sid + url_pos.to_json
    #    FileManager.rails_logger("generate_url pdata = [" + pdata + "]")

    # make encrypted data
    file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata

    # basew64 url safe encoding
    fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])

    my_server_params = SpinFileServer.find_by_server_port server_port
    my_spin_url = my_server_params[:spin_url_server_name] + SYSTEM_DEFAULT_PUBLIC_URL_DOWNLOADER + '/' + fmargs

    # search spin_urls node
    url_rec = self.find_by_nx_and_ny_and_nv(url_pos[X], url_pos[Y], url_pos[V])

    if url_rec == nil
      url_rec = self.new
    end

    url_rec[:nx] = url_pos[X]
    url_rec[:ny] = url_pos[Y]
    url_rec[:nprx] = url_pos[PRX]
    url_rec[:nv] = url_pos[V]
    url_rec[:nt] = url_pos[T]
    url_rec[:spin_url] = my_spin_url
    url_rec[:spin_node_name] = open_file_name

    unless url_rec.save
      return ''
    else
      return my_spin_url
    end
  end

  # => end of self.generate_url node_key, expires_at = EXPIRE_100_YEARS_AFTER

  def self.generate_display_url sid, open_file_key, open_file_name, server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    rsa_key_pem = SpinNode.get_root_rsa_key
    pdata = sid + open_file_key + open_file_name
    # make encrypted data
    file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata

    # basew64 url safe encoding
    fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])

    my_server_params = SpinFileServer.find_by_server_port server_port
    my_spin_url = my_server_params[:spin_url_server_name] + SYSTEM_DEFAULT_URL_DOWNLOADER + '/' + fmargs

    return my_spin_url
  end # => end of self.generate_url node_key, expires_at = EXPIRE_100_YEARS_AFTER

end
