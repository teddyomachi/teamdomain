# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'utilities/image_utilities'

class FileDatum < ActiveRecord::Base
  include Vfs
  include Acl
  include Stat

  attr_accessor :access_group, :client, :cont_location, :control_right, :copyright, :created_date, :creator, :description, :details, :dirty, :duration, :file_exact_size, :file_name, :file_readable_status, :file_size, :file_size_upper, :file_type, :file_version, :file_writable_status, :folder_hash_key, :folder_readable_status, :folder_writable_status, :frame_size, :hash_key, :icon_image, :id_lc_by, :keyword, :location, :lock, :modified_date, :modifier, :id_lc_name, :open_status, :owner, :ownership, :portrait_right, :produced_date, :producer, :session_id, :subtitle, :thumbnail_image, :title, :url

  TREE_NOT_INCLUDE_ROOT = false
  TREE_INCLUDE_ROOT = true
  FOLDER_TYPE = "folder"

  def self.fill_file_list_data_table ssid, last_ssid, my_uid, location, current_folder_key, mobile_list = false
    # Is it dirty?
    #    is_dirty_list = FolderDatum.is_dirty_folder(ssid, location, current_folder_key, true)

    # get location of currentg directory
    cd_loc = SpinLocationManager.key_to_location current_folder_key, NODE_DIRECTORY

    total = 0
    file_list_nodes = []
    # get spin_domain
    dom = FolderDatum.select("domain_hash_key").find_by_session_id_and_cont_location_and_spin_node_hashkey(ssid, location, current_folder_key)
    if dom.present?
      domain_hash_key = dom[:domain_hash_key]
    else
      domain_hash_key = SpinUser.get_default_domain(ssid)
      if domain_hash_key.blank?
        file_list_nodes
      end
    end

    acls = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    acls_p = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    pkey = ''

    #    ActiveRecord::Base::lock_optimistically = false
    saved_records = 0

    total = 0

    retry_fill_file_list_data_table = ACTIVE_RECORD_RETRY_COUNT
    catch(:fill_file_list_data_table_again) {
      FileDatum.transaction do
        begin
          file_list_nodes = SpinNode.readonly.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND in_trash_flag = false AND is_void = false AND is_pending = false", SPIN_NODE_VTREE, cd_loc[X], cd_loc[Y] + 1]).order("node_name ASC, node_version DESC") # => includes files and directories in the current directory
          #    file_list_nodes = SpinNode.readonly.where( :node_x_pr_coord => cd_loc[X], :node_y_coord => cd_loc[Y]+1, :in_trash_flag => false, :is_void => false ).order("node_name ASC, node_version DESC") # => includes files and directories in the current directory

          if (file_list_nodes.present? and file_list_nodes.length == 0) or file_list_nodes.blank?
            return {:success => true, :status => INFO_NO_FILES, :total => 0, :result => 0}
          end

          total = file_list_nodes.length

          last_update = file_list_nodes[0][:spin_updated_at]
          file_list_nodes.each {|t|
            if t[:spin_updated_at] > last_update
              last_update = t[:spin_updated_at]
            end
            if t[:trashed_at] > last_update
              last_update = t[:trashed_at]
            end
          }

          folder_hash_key = current_folder_key

          # build FolderData
          #    file_list_rec = Hash.new
          reuse_last = false
          file_type_icons = $file_type_icons
          #    file_list_rec = nil
          #    FileDatum.transaction do
          pkey_aquired = false
          #    FileDatum.transaction do
          file_list_nodes.each {|fn|

            next if fn[:node_name].blank?
            if my_uid == 0
              acls = {:user => ACL_NODE_SUPERUSER_ACCESS, :group => ACL_NODE_SUPERUSER_ACCESS, :world => fn[:spin_world_access_right]}
            else
              acls = SpinAccessControl.has_acl_values ssid, fn[:spin_node_hashkey], ANY_TYPE
            end
            unless pkey_aquired
              pn = SpinLocationManager.get_parent_node(fn)
              next if pn.blank?
              pkey = pn[:spin_node_hahskey]
              acls_p = SpinAccessControl.has_acl_values(ssid, pkey, ANY_TYPE)
              pkey_aquired = true
            end
            if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS or acls[:world] > ACL_NODE_NO_ACCESS # => match!
              #          file_list_rec = self.find_by_spin_node_hashkey_and_session_id_and_cont_location fn[:spin_node_hashkey],  ssid, location
              file_list_recs = self.where(["spin_node_hashkey = ? AND session_id = ? AND cont_location = ? AND folder_hash_key = ?", fn[:spin_node_hashkey], ssid, location, folder_hash_key]).order("file_version DESC")
              #          file_list_recs = self.where(["file_name = ? AND session_id = ? AND cont_location = ? AND folder_hash_key = ?",fn[:node_name],  ssid, location, folder_hash_key],:order=>"file_version DESC")
              if file_list_recs.present? && file_list_recs.length > 0 # => there is file list data
                file_list_recs.each_with_index {|file_list_rec, idx|
                  unless idx == 0
                    begin
                      file_list_rec.destroy
                      next
                    rescue ActiveRecord::StaleObjectError
                      FileManager.logger(ssid, "file record is alread removed")
                    end
                  end
                  if file_list_rec[:spin_updated_at] < last_update # => modified node!
                    retry_save = ACTIVE_RECORD_RETRY_COUNT

                    if reuse_last
                      file_list_rec[:session_id] = ssid
                    end
                    if idx == 0
                      file_list_rec[:latest] = true
                    else
                      file_list_rec[:latest] = false
                    end
                    # attr = JSON.parse fn[:node_attributes]
                    attr = nil
                    begin
                      attr = JSON.parse fn[:node_attributes]
                    rescue
                      attr = nil
                    end
                    file_list_rec[:file_name] = fn[:node_name]
                    file_list_rec[:latest] = fn[:latest]
                    #                file_list_rec[:file_readable_status] = SpinAccessControl.is_readable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
                    #                file_list_rec[:file_writable_status] = SpinAccessControl.is_writable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
                    file_list_rec[:file_readable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
                    file_list_rec[:file_writable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                    #                file_list_rec[:folder_readable_status] = SpinAccessControl.is_readable(ssid, pkey, ANY_TYPE)
                    #                file_list_rec[:folder_writable_status] = SpinAccessControl.is_writable(ssid, pkey, ANY_TYPE)
                    file_list_rec[:folder_readable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
                    file_list_rec[:file_writable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                    file_list_rec[:cont_location] = location
                    if fn[:node_type] == NODE_DIRECTORY
                      file_list_rec[:file_type] = FOLDER_TYPE;
                      file_list_rec[:icon_image] = "file_type_icon/FolderDocument.png"
                      file_list_rec[:thumbnail_image] = "file_type_icon/FolderDocument.png"
                      file_list_rec[:t_file_type] = 'png';
                    else
                      ftype = ''
                      if fn[:node_name].include?('.')
                        ftype = fn[:node_name].split('.')[-1]
                      end
                      file_list_rec[:file_type] = ftype
                      file_list_rec[:icon_image] = "file_type_icon/unknown.png"
                      #file_list_rec[:icon_image] = "file_type_icon/test.pdf"
                      if file_type_icons.present?
                        file_type_icons.each {|key, value|
                          next if ftype.blank?
                          if /#{ftype}/i =~ key
                            file_list_rec[:icon_image] = value
                            break
                          end
                        }
                      end

                      c_type = self.get_content_type(ftype)
                      if c_type.present? && c_type == C_PICTURE_TYPE
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, file_list_rec[:hash_key]
                        if my_thumbnail.blank?
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        elsif my_thumbnail =~ /(http:|https:)/
                          file_list_rec[:thumbnail_image] = my_thumbnail
                          #                      file_list_rec[:t_file_type] = 'png'
                        else
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        end
                        file_list_rec[:t_file_type] = 'png'
                      elsif c_type.present? && c_type == C_VIDEO_TYPE
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_PROXY_MOVIE, file_list_rec[:hash_key]
                        if my_thumbnail.blank?
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                          file_list_rec[:t_file_type] = 'png'
                        elsif my_thumbnail =~ /(http:|https:)/
                          file_list_rec[:thumbnail_image] = my_thumbnail
                          file_list_rec[:t_file_type] = 'mp4'
                        else
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                          file_list_rec[:t_file_type] = 'png'
                        end
                      else
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, file_list_rec[:hash_key]
                        if my_thumbnail.blank?
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        elsif my_thumbnail =~ /(http:|https:)/
                          file_list_rec[:thumbnail_image] = my_thumbnail
                        else
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        end
                        file_list_rec[:t_file_type] = 'pdf'
                      end
                    end
                    file_list_rec[:spin_node_hashkey] = fn[:spin_node_hashkey]
                    file_list_rec[:file_size] = fn[:node_size]
                    file_list_rec[:file_size_upper] = fn[:node_size_upper]
                    # file_list_rec[:file_size] = ( (attr and attr[:file_size])? attr[:file_size] : "-" )
                    file_list_rec[:url] = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_FILE, file_list_rec[:hash_key]
                    #              file_list_rec[:file_exact_size] =  fn[:node_size]
                    # file_list_rec[:file_exact_size] =  ( (attr and attr[:file_exact_size])? attr[:file_exact_size] : "-" )
                    file_list_rec[:file_version] = fn[:node_version]
                    file_list_rec[:creator] = SpinUserAttribute.get_user_name fn[:spin_uid]
                    file_list_rec[:modified_date] = fn[:mtime] == nil ? Time.now : fn[:mtime]
                    file_list_rec[:spin_updated_at] = fn[:spin_updated_at]
                    file_list_rec[:spin_created_at] = fn[:spin_created_at]
                    file_list_rec[:modifier] = SpinUserAttribute.get_user_name fn[:updated_by]
                    file_list_rec[:owner] = SpinUserAttribute.get_user_name fn[:spin_uid]
                    file_list_rec[:ownership] = (fn[:spin_uid] == my_uid) ? "me" : "other"
                    file_list_rec[:control_right] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_CONTROL) != 0 ? true : false) # (((SpinAccessControl.has_acl ssid, fn[:spin_node_hashkey])&ACL_NODE_CONTROL) != 0 ? true : false ) # ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_CONTROL) != 0? true : false
                    file_list_rec[:dirty] = true # => may be
                    file_list_rec[:description] = fn[:node_description]
                    file_list_rec[:details] = fn[:details]

                    # ロック状態更新
                    if fn[:lock_uid] != my_uid && fn[:lock_uid] != -1
                      # 他ユーザがロックしている場合は、ロックステータスの状態に関わらず排他ロックとする
                      # →データ不整合時のデッドロック防止
                      file_list_rec[:lock] = FSTAT_LOCKED_EXCLUSIVE
                    else
                      if fn[:lock_uid] == my_uid
                        file_list_rec[:lock] = FSTAT_LOCKED
                      else
                        file_list_rec[:lock] = FSTAT_UNLOCKED
                      end
                    end

                    if fn[:lock_uid] >= 0
                      file_list_rec[:id_lc_by] = SpinUser.get_uname fn[:lock_uid]
                      file_list_rec[:id_lc_name] = SpinUserAttribute.get_user_name fn[:lock_uid]
                    else
                      file_list_rec[:id_lc_by] = ""
                      file_list_rec[:id_lc_name] = ""
                    end
                    #            file_list_rec[:open_status] = fn[:is_open_flag]
                    if attr.present?
                      file_list_rec[:title] = attr['title'] rescue ""
                      # file_list_rec[:type] = file_list_rec[:file_type]
                      file_list_rec[:subtitle] = attr['subtitle'] rescue ""
                      file_list_rec[:frame_size] = attr['frame_size'] rescue ""
                      file_list_rec[:duration] = attr['duration'] rescue ""
                      file_list_rec[:producer] = attr['producer'] rescue ""
                      #file_list_rec[:produced_date] = ( attr['produced_date'] ? attr['produced_date'].to_time : "-" )
                      file_list_rec[:produced_date] = attr['produced_date'] rescue ""
                      file_list_rec[:location] = attr['location'] rescue ""
                      file_list_rec[:cast] = attr['cast'] rescue ""
                      file_list_rec[:client] = attr['client'] rescue ""
                      file_list_rec[:copyright] = attr['copyright'] rescue ""
                      file_list_rec[:music] = attr['music'] rescue ""
                      file_list_rec[:keyword] = attr['keyword'] rescue ""
                      #                  file_list_rec[:description] = ( attr['description'] ? attr['description'] : "" )
                    else
                      file_list_rec[:title] = ""
                      # file_list_rec[:type] = file_list_rec[:file_type]
                      file_list_rec[:subtitle] = ""
                      file_list_rec[:frame_size] = ""
                      file_list_rec[:duration] = ""
                      file_list_rec[:producer] = ""
                      #file_list_rec[:produced_date] = "-"
                      file_list_rec[:produced_date] = ""
                      file_list_rec[:location] = ""
                      file_list_rec[:cast] = ""
                      file_list_rec[:client] = ""
                      file_list_rec[:copyright] = ""
                      file_list_rec[:music] = ""
                      file_list_rec[:keyword] = ""
                      #                  file_list_rec[:description] = ""
                    end
                    file_list_rec.save # => save = update database
                    saved_records += 1
                    #                SessionManager.set_location_clean(ssid, location)
                  else # =>  file_list_rec[:updated_at] >= fn.updated_at
                    if reuse_last # => rewrite session_id to ssid

                      if fn[:latest] == true
                        #                  current_latest_nodes = self.where :session_id => ssid, :cont_location => location, :file_name => fn[:node_name]
                        #                  FileDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')

                        FileDatum.transaction do
                          #                    self.find_by_sql("SELECT id FROM file_data WHERE session_id = \'#{ssid}\' AND cont_location = \'#{location}\' AND folder_hash_key = \'#{folder_hash_key}\' AND file_name = \'#{fn[:node_name]}\' FOR UPDATE;")
                          current_latest_nodes = self.where :session_id => ssid, :cont_location => location, :folder_hash_key => folder_hash_key, :file_name => fn[:node_name]
                          if current_latest_nodes.present?
                            current_latest_nodes.each {|cn|
                              begin
                                if cn[:spin_node_hashkey] == fn[:spin_node_hashkey]
                                  cn[:latest] = true
                                else
                                  cn[:latest] = false
                                end
                                #                        cn[:latest] = false
                                cn.save
                              rescue ActiveRecord::StaleObjectError
                                sleep(AR_RETRY_WAIT_MSEC)
                                throw :fill_file_list_data_table_again
                              end
                            }
                          end
                        end
                      end

                      file_list_rec[:session_id] = ssid
                      if idx == 0
                        file_list_rec[:latest] = true
                      else
                        file_list_rec[:latest] = false
                      end
                      # file_list_rec[:leaf] = true
                      file_list_rec.save # => save = update database
                      saved_records += 1
                    else # => don't reuse
                      # do nothing but increment saved_records
                      saved_records += 1
                      # FolderDatum.has_updated ssid, current_directory_key
                    end # => end of if reuse_last
                    ####
                  end # => if file_list_rec[:updated_at] < d.updated_at
                }
              else # => no file rec's, new node! uploaded, copied or moved.
                if last_ssid.present?
                  #            file_list_rec = self.find_by_spin_node_hashkey_and_session_id_and_cont_location fn[:spin_node_hashkey], last_ssid, location
                  #            file_list_rec = self.find_by_spin_node_hashkey_and_session_id_and_cont_location_and_folder_hash_key fn[:spin_node_hashkey], last_ssid, location, current_folder_key
                  #            file_list_recs = self.where(["spin_node_hashkey = ? AND session_id = ? AND cont_location = ? AND folder_hash_key = ?",fn[:spin_node_hashkey],  last_ssid, location, folder_hash_key],:order=>"file_version DESC")
                  #            file_list_recs = self.where(["file_name = ? AND session_id = ? AND cont_location = ? AND folder_hash_key = ?",fn[:node_name],  last_ssid, location, folder_hash_key],:order=>"file_version DESC")
                  reuse_last = true
                end
                attr = nil
                jstst = fn[:node_attributes]
                if jstst.present? && jstst =~ /\{\s*\"\w+\"\s*\:\s*\"\w+\"\s*\}/
                  attr = JSON.parse fn[:node_attributes]
                end
                new_file_list_datum = FileDatum.new {|new_file_list_datum|
                  new_file_list_datum[:session_id] = ssid
                  r = Random.new
                  my_hash_key = Security.hash_key_s(ssid + fn[:spin_node_hashkey] + location + r.rand.to_s)
                  new_file_list_datum[:hash_key] = my_hash_key
                  #            new_file_list_datum[:hash_key] = fn[:spin_node_hashkey]
                  new_file_list_datum[:spin_node_hashkey] = fn[:spin_node_hashkey]
                  new_file_list_datum[:folder_hash_key] = folder_hash_key
                  new_file_list_datum[:domain_hash_key] = domain_hash_key
                  #            attr = ( fn[:node_attributes'] ? (JSON.parse fn[:node_attributes]) : '{ "key": "value" }' )
                  new_file_list_datum[:file_name] = fn[:node_name]
                  new_file_list_datum[:latest] = fn[:latest]
                  #            new_file_list_datum[:file_readable_status] = SpinAccessControl.is_readable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
                  #            new_file_list_datum[:file_writable_status] = SpinAccessControl.is_writable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
                  new_file_list_datum[:file_readable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
                  new_file_list_datum[:file_writable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                  #            pkey = SpinLocationManager.get_parent_key(fn[:spin_node_hashkey], ANY_TYPE)
                  #            new_file_list_datum[:folder_readable_status] = SpinAccessControl.is_readable(ssid, pkey, ANY_TYPE)
                  #            new_file_list_datum[:folder_writable_status] = SpinAccessControl.is_writable(ssid, pkey, ANY_TYPE)
                  #            acls_p = SpinAccessControl.has_acl_values ssid, pkey, ANY_TYPE
                  new_file_list_datum[:folder_readable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
                  new_file_list_datum[:file_writable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                  # new_file_list_datum[:icon_image] = "file_type_icon/FolderDocument.png"
                  new_file_list_datum[:cont_location] = location
                  # new_file_list_datum[:file_type] = ( fn[:node_type] == NODE_DIRECTORY ? FOLDER_TYPE : fn[:node_name].split('.')[-1] )
                  if fn[:node_type] == NODE_DIRECTORY
                    new_file_list_datum[:file_type] = FOLDER_TYPE;
                    new_file_list_datum[:icon_image] = "file_type_icon/FolderDocument.png"
                    new_file_list_datum[:thumbnail_image] = "file_type_icon/FolderDocument.png"
                    new_file_list_datum[:t_file_type] = 'png';
                  else
                    ftype = ''
                    if fn[:node_name].include?('.')
                      ftype = fn[:node_name].split('.')[-1]
                    end
                    new_file_list_datum[:file_type] = ftype
                    new_file_list_datum[:icon_image] = "file_type_icon/unknown.png"
                    if $file_type_icons.present?
                      file_type_icons.each {|key, value|
                        next if ftype.blank?
                        if /#{ftype}/i =~ key
                          new_file_list_datum[:icon_image] = value
                          break
                        end
                      }
                    end

                    c_type = self.get_content_type(ftype)
                    if c_type.present? && c_type == C_PICTURE_TYPE
                      my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, new_file_list_datum[:hash_key]
                      if my_thumbnail.blank?
                        new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                      elsif my_thumbnail =~ /(http:|https:)/
                        new_file_list_datum[:thumbnail_image] = my_thumbnail
                      else
                        new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                      end
                      new_file_list_datum[:t_file_type] = 'png'
                    elsif c_type.present? && c_type == C_VIDEO_TYPE
                      my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_PROXY_MOVIE # SpinUrl.get_url(new_file_list_datum[:hash_key])
                      if my_thumbnail.blank?
                        new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                        new_file_list_datum[:t_file_type] = 'png'
                      elsif my_thumbnail =~ /(http:|https:)/
                        new_file_list_datum[:thumbnail_image] = my_thumbnail
                        new_file_list_datum[:t_file_type] = 'mp4'
                      else
                        new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                        new_file_list_datum[:t_file_type] = 'png'
                      end
                      #                new_file_list_datum[:t_file_type] = 'mp4'
                    else
                      my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL # SpinUrl.get_url(new_file_list_datum[:hash_key])
                      if my_thumbnail.blank?
                        new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                        #new_file_list_datum[:thumbnail_image] ='file_type_icon/test'
                      elsif my_thumbnail =~ /(http:|https:)/
                        new_file_list_datum[:thumbnail_image] = my_thumbnail
                      else
                        new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                      end
                      new_file_list_datum[:t_file_type] = 'pdf'
                    end
                  end
                  new_file_list_datum[:url] = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_FILE, my_hash_key
                  new_file_list_datum[:file_size] = fn[:node_size]
                  new_file_list_datum[:file_size_upper] = fn[:node_size_upper]
                  #            new_file_list_datum[:file_exact_size] = fn[:node_size]
                  new_file_list_datum[:file_version] = fn[:node_version]
                  new_file_list_datum[:created_date] = fn[:ctime] == nil ? Time.now : fn[:ctime]
                  new_file_list_datum[:creator] = SpinUserAttribute.get_user_name fn[:created_by]
                  new_file_list_datum[:modified_date] = fn[:mtime] == nil ? Time.now : fn[:mtime]
                  new_file_list_datum[:spin_updated_at] = fn[:spin_updated_at]
                  new_file_list_datum[:spin_created_at] = fn[:spin_created_at]
                  # new_file_list_datum[:modified_date] = fn[:updated_at]
                  new_file_list_datum[:modifier] = SpinUserAttribute.get_user_name fn[:spin_uid]
                  new_file_list_datum[:owner] = SpinUserAttribute.get_user_name fn[:spin_uid]
                  new_file_list_datum[:ownership] = (fn[:spin_uid] == my_uid) ? "me" : "other"
                  new_file_list_datum[:control_right] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_CONTROL) != 0 ? true : false)
                  new_file_list_datum[:dirty] = fn[:is_dirty_flag]
                  new_file_list_datum[:open_status] = false
                  new_file_list_datum[:description] = fn[:node_description]
                  new_file_list_datum[:details] = fn[:details]

                  # ロック状態更新
                  if fn[:lock_uid] != my_uid && fn[:lock_uid] != -1
                    # 他ユーザがロックしている場合は、ロックステータスの状態に関わらず排他ロックとする
                    # →データ不整合時のデッドロック防止
                    new_file_list_datum[:lock] = FSTAT_LOCKED_EXCLUSIVE
                  else
                    if fn[:lock_uid] == my_uid
                      new_file_list_datum[:lock] = FSTAT_LOCKED
                    else
                      new_file_list_datum[:lock] = FSTAT_UNLOCKED
                    end
                  end

                  if fn[:lock_uid] >= 0
                    new_file_list_datum[:id_lc_by] = SpinUser.get_uname fn[:lock_uid]
                    new_file_list_datum[:id_lc_name] = SpinUserAttribute.get_user_name fn[:lock_uid]
                  else
                    new_file_list_datum[:id_lc_by] = ""
                    new_file_list_datum[:id_lc_name] = ""
                  end

                  if attr.present?
                    new_file_list_datum[:title] = (attr['title'] ? attr['title'] : "")
                    # new_file_list_datum[:type] = new_file_list_datum[:file_type]
                    new_file_list_datum[:subtitle] = (attr['subtitle'] ? attr['subtitle'] : "")
                    new_file_list_datum[:frame_size] = (attr['frame_size'] ? attr['frame_size'].to_s : "")
                    new_file_list_datum[:duration] = (attr['duration'] ? attr['duration'] : "")
                    new_file_list_datum[:producer] = (attr['producer'] ? attr['producer'] : "")
                    #new_file_list_datum[:produced_date] = ( attr['produced_date'] ? attr['produced_date'].to_time : "-" )
                    new_file_list_datum[:produced_date] = (attr['produced_date'] ? attr['produced_date'] : "")
                    new_file_list_datum[:location] = (attr['location'] ? attr['location'] : "")
                    new_file_list_datum[:cast] = (attr['cast'] ? attr['cast'] : "")
                    new_file_list_datum[:client] = (attr['client'] ? attr['client'] : "")
                    new_file_list_datum[:copyright] = (attr['copyright'] ? attr['copyright'] : "")
                    new_file_list_datum[:music] = (attr['music'] ? attr['music'] : "")
                    new_file_list_datum[:keyword] = (attr['keyword'] ? attr['keyword'] : "")
                    #              new_file_list_datum[:description] = ( attr['description'] ? attr['description'] : "" )
                  else
                    new_file_list_datum[:subtitle] = ""
                    new_file_list_datum[:frame_size] = ""
                    new_file_list_datum[:duration] = ""
                    new_file_list_datum[:producer] = ""
                    #new_file_list_datum[:produced_date] = "-"
                    new_file_list_datum[:produced_date] = ""
                    new_file_list_datum[:location] = ""
                    new_file_list_datum[:cast] = ""
                    new_file_list_datum[:client] = ""
                    new_file_list_datum[:copyright] = ""
                    new_file_list_datum[:music] = ""
                    new_file_list_datum[:keyword] = ""
                    #              new_file_list_datum[:description] = ""
                  end
                  unless new_file_list_datum[:created_date].present?
                    new_file_list_datum[:created_date] = Time.now
                  end
                }
                new_file_list_datum.save # => save = update database
                saved_records += 1
                nret = SpinNotifyControl.has_notification(ssid, current_folder_key, NODE_DIRECTORY)
                #                if fn[:notify_type] < 0 and new_file_list_datum[:file_type] != 'folder'
                if fn[:notify_type] < 0 and fn[:node_type] == NODE_FILE
                  thr = Thread.new do
                    if fn[:node_version] > 1 and fn[:notified_modification_at].to_time == SYSTEM_DEFAULT_TIMESTAMP_STRING.to_time
                      #                    if new_file_list_datum[:file_version] > 1
                      SpinNotifyControl.notify_modification(ssid, current_folder_key, fn[:spin_node_hashkey], new_file_list_datum[:url], domain_hash_key)
                    else
                      SpinNotifyControl.notify_new(ssid, current_folder_key, fn[:spin_node_hashkey], new_file_list_datum[:url], domain_hash_key)
                    end
                  end
                  #                elsif fn[:notified_new_at] > SYSTEM_DEFAULT_TIMESTAMP_STRING.to_time
                  #                  thr = Thread.new do
                  #                    SpinNotifyControl.notify_modification(ssid,current_folder_key,fn[:spin_node_hashkey],new_file_list_datum[:url],domain_hash_key)
                  #                  end
                end # => ne dof if fn[:notify_type] < 0 and new_file_list_datum[:file_type] != 'folder'
              end # => end of if new_file_list_datum
            end # => end of if acls[:user

          } # =>  end of folder_tree_nodes.each
        rescue ActiveRecord::StaleObjectError
          if retry_fill_file_list_data_table > 0
            retry_fill_file_list_data_table -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :fill_file_list_data_table_again
          end
        end
      end # => end of transaction
    } # => end of catch block

    SessionManager.set_location_clean(ssid, location, true)
    return {:success => true, :status => true, :total => total, :result => saved_records}
  end

  def self.fill_file_list ssid, location, my_current_folder, mobile_list = false
    # gproduced_dateet uid and gid
    rethash = {}
    #    ActiveRecord::Base::lock_optimistically = false
    FileDatum.transaction do
      #      FileDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      my_uid = SessionManager.get_uid ssid
      # get current domain at the location
      session_rec = {}
      #    FileDatum.transaction do
      session_rec = SpinSession.readonly.find_by_spin_session_id ssid
      #    end
      logger.debug location
      logger.debug session_rec
      #    my_current_directory = String.new
      last_session = SessionManager.get_last_session ssid
      #    if current_folder.blank?
      #      case location
      #      when 'folder_a'
      #        my_current_directory = session_rec[:selected_folder_a]
      #      when 'folder_b'
      #        my_current_directory = session_rec[:selected_folder_b]
      #      else
      #        my_current_directory = session_rec[:selected_folder_a]
      #      end
      #    else
      #      my_current_directory = current_directory
      #    end
      rethash = Hash.new
      # search spin_folders and spin_access_control, and fill domain table
      file_list_b_location = 'file_listB'
      if location != file_list_b_location
        rethash = fill_file_list_data_table ssid, last_session, my_uid, location, my_current_folder, mobile_list
      end
    end # => end of transaction
    # rethash = FolderDatum.where(:session_id => ssid).order("spin_did")
    return rethash
  end

  # => end of fill_file_lists

  def self.active_list sid, cont_location, folder_hash_key
    active_list = Array.new
    #    ActiveRecord::Base::lock_optimistically = false
    FileDatum.transaction do
      file_list = FileDatum.where(["session_id = ? AND cont_location = ? AND folder_hash_key = ? AND latest = true", sid, cont_location, folder_hash_key]).order("file_name ASC")
      file_list.each {|f|
        if SpinNode.is_active_node f[:hash_key]
          active_list.append f
        end
      }
    end
    return active_list
  end

  # => end of self.active_list sid, cont_location, folder_hash_key

  def self.get_file_list_display_data sid, cont_location, offset, limit
    rethash = {:success => false, :total => 0, :display_object => []}
    total = 0

    cwd = SessionManager.get_selected_folder(sid, cont_location)
    if cwd.blank?
      cfds = FolderDatum.where(["session_id = ? AND cont_location = ? AND selected = true", sid, cont_location])
      if cfds.blank?
        rethash[:success] = true
        rethash[:total] = 0
        rethash[:start] = offset
        rethash[:limit] = limit
        rethash[:display_object] = []
        return rethash
      end
    end

    cfd = FolderDatum.find_by_session_id_and_cont_location_and_spin_node_hashkey sid, cont_location, cwd
    if cfd.blank?
      rethash[:success] = false
      rethash[:total] = -1
      rethash[:start] = offset
      rethash[:limit] = limit
      rethash[:display_object] = []
      return rethash
    end
    #      ActiveRecord::Base.lock_optimistically = false
    file_list = Array.new
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:get_file_list_display_data_again) {
      FileDatum.transaction do
        file_list = FileDatum.limit(limit).offset(offset).where(["session_id = ? AND cont_location = ? AND folder_hash_key = ? AND latest = true", sid, cont_location, cfd[:spin_node_hashkey]]).order("file_name ASC")
        #        recs = FileDatum.select("id").where(["session_id = ? AND cont_location = ? AND folder_hash_key = ? AND latest = true", sid, cont_location, cfd[:spin_node_hashkey]])
        #        total = recs.length
        total = file_list.size

        begin
          file_list.each {|fl|
            acls_f = SpinAccessControl.has_acl_values(sid, fl[:folder_hash_key], NODE_FILE)
            acls = SpinAccessControl.has_acl_values(sid, fl[:spin_node_hashkey], NODE_FILE)
            fl[:folder_readable_status] = (((acls_f[:user] | acls_f[:group] | acls_f[:world]) & ACL_NODE_READ) != 0 ? true : false)
            fl[:folder_writable_status] = (((acls_f[:user] | acls_f[:group] | acls_f[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
            fl[:control_right] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_CONTROL) != 0 ? true : false)
            fl[:file_readable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
            fl[:file_writable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
            fl[:other_readable] = ((acls[:world] & ACL_NODE_READ) != 0 ? true : false)
            fl[:other_writable] = ((acls[:world] & ACL_NODE_WRITE) != 0 ? true : false)
            fl[:created_at] = (fl[:spin_created_at] == nil ? fl[:spin_updated_at] : fl[:spin_created_at])
            fl[:updated_at] = fl[:spin_updated_at]
            # 仮想パス取得
            fn = SpinNode.find_by_spin_node_hashkey fl[:spin_node_hashkey]
            if fn.present?
              fl[:virtual_path] = fn[:virtual_path]
            end
            fl.save
          }
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count < 0
            rethash[:success] = false
            rethash[:total] = total * (-1)
            rethash[:start] = offset
            rethash[:limit] = limit
            rethash[:display_object] = nil
            return rethash
          end
          sleep(AR_RETRY_WAIT_MSEC)
          throw :get_file_list_display_data_again
        end
      end # => end of transaction
    } # => end of catch block

    if file_list.blank?
      rethash[:success] = false
      rethash[:total] = total * (-1)
      rethash[:start] = offset
      rethash[:limit] = limit
      rethash[:display_object] = []
      return rethash
    else
      rethash[:success] = true
      rethash[:total] = total
      rethash[:start] = offset
      rethash[:limit] = limit
      rethash[:display_object] = file_list
      return rethash
    end
  end

  # => end of get_file_list_display_data

  def self.set_selected sid, node_key, cont_location = LOCATION_A
    location = LOCATION_A
    if /folder_a/ =~ cont_location
      location = LOCATION_A
    elsif /folder_b/ =~ cont_location
      location = LOCATION_B
    end
    #    ActiveRecord::Base::lock_optimistically = false
    retry_set_selected = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_selected_again) {
      self.transaction do
        frec = self.where(["spin_node_hashkey = ? AND session_id = ? AND cont_location = ?", node_key, sid, location])
        frec.each {|f|
          begin
            f[:selected] = true
            f.save
          rescue ActiveRecord::StaleObjectError
            if retry_set_selected > 0
              retry_set_selected -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :set_selected_again
            else
              throw ActiveRecord::StaleObjectError
            end
          end
        }
      end # => end of transaction
    } # => end of catch block
    return true
  end

  # => end of self.set_selected sid, node_key

  def self.reset_selected sid, node_key
    #    ActiveRecord::Base::lock_optimistically = false
    catch(:reset_selected_again) {
      self.transaction do
        frec = self.where(["spin_node_hashkey = ? AND session_id = ?", node_key, sid])
        frec.each {|f|
          begin
            f[:selected] = false
            f.save
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :reset_selected_again
          end
        }
      end # => end of transaction
    } # => end of catch block
  end

  # => end of self.set_selected sid, node_key

  def self.load_file_list_rec ssid, location, node_key, folder_key
    #    get folder_hash_key
    folder_hash_key = ''
    domain_hash_key = ''
    folrec = FolderDatum.find_by_session_id_and_cont_location_and_spin_node_hashkey(ssid, location, folder_key)
    if folrec.present?
      folder_hash_key = folrec[:hash_key]
      domain_hash_key = folrec[:domain_hash_key]
    else
      return {:success => false, :status => ERROR_FAILED_TO_FIND_PARENT_FOLDER, :total => -1, :errors => 'Failed find parent folder of this file list.'}
    end

    my_uid = SessionManager.get_uid(ssid)
    # find spin node
    fn = SpinNode.find_by_spin_node_hashkey node_key

    file_type_icons = $file_type_icons
    #    file_list_rec = nil
    #    FileDatum.transaction do
    #    FileDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    #    ActiveRecord::Base::lock_optimistically = false
    retry_save = ACTIVE_RECORD_RETRY_COUNT

    catch(:load_file_list_rec_again) {

      FileDatum.transaction do
        #      FileDatum.find_by_sql('LOCK TABLE file_data IN ROW EXCLUSIVE MODE;')

        begin
          attr = (fn[:node_attributes].length > 2 ? (JSON.parse fn[:node_attributes]) : nil)

          new_file_list_datum = FileDatum.new {|new_file_list_datum|
            new_file_list_datum[:session_id] = ssid
            r = Random.new
            my_hash_key = Security.hash_key_s(ssid + fn[:spin_node_hashkey] + location + r.rand.to_s)
            new_file_list_datum[:hash_key] = my_hash_key
            new_file_list_datum[:target_hash_key] = my_hash_key
            #            new_file_list_datum[:hash_key] = fn[:spin_node_hashkey]
            new_file_list_datum[:spin_node_hashkey] = fn[:spin_node_hashkey]
            new_file_list_datum[:folder_hash_key] = folder_hash_key
            #            attr = ( fn[:node_attributes'] ? (JSON.parse fn[:node_attributes]) : '{ "key": "value" }' )
            new_file_list_datum[:file_name] = fn[:node_name]
            new_file_list_datum[:latest] = fn[:latest]
            new_file_list_datum[:file_readable_status] = SpinAccessControl.is_readable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
            new_file_list_datum[:file_writable_status] = SpinAccessControl.is_writable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
            pn = SpinLocationManager.get_parent_node(fn)
            pkey = pn[:spin_node_hashkey]
            new_file_list_datum[:folder_readable_status] = SpinAccessControl.is_readable(ssid, pkey, ANY_TYPE)
            new_file_list_datum[:folder_writable_status] = SpinAccessControl.is_writable(ssid, pkey, ANY_TYPE)
            # new_file_list_datum[:icon_image] = "file_type_icon/FolderDocument.png"
            new_file_list_datum[:cont_location] = location
            # new_file_list_datum[:file_type] = ( fn[:node_type] == NODE_DIRECTORY ? FOLDER_TYPE : fn[:node_name].split('.')[-1] )
            if fn[:node_type] == NODE_DIRECTORY
              new_file_list_datum[:file_type] = FOLDER_TYPE;
              new_file_list_datum[:icon_image] = "file_type_icon/FolderDocument.png"
              new_file_list_datum[:thumbnail_image] = "file_type_icon/FolderDocument.png"
              new_file_list_datum[:t_file_type] = 'png';
            else
              ftype = ''
              if fn[:node_name].include?('.')
                ftype = fn[:node_name].split('.')[-1]
              end
              new_file_list_datum[:file_type] = ftype
              new_file_list_datum[:icon_image] = "file_type_icon/unknown.png"
              if file_type_icons.present?
                file_type_icons.each {|key, value|
                  next if ftype.blank?
                  if /#{ftype}/i =~ key
                    new_file_list_datum[:icon_image] = value
                    break
                  end
                }
              end
              c_type = self.get_content_type(ftype)
              if c_type == C_PICTURE_TYPE
                my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, my_hash_key
                if my_thumbnail.blank?
                  new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                elsif my_thumbnail =~ /(http:|https:)/
                  new_file_list_datum[:thumbnail_image] = my_thumbnail
                else
                  new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                end
                new_file_list_datum[:t_file_type] = 'png'
              elsif c_type == C_VIDEO_TYPE
                my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_PROXY_MOVIE, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                if my_thumbnail.blank?
                  new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                  new_file_list_datum[:t_file_type] = 'png'
                elsif my_thumbnail =~ /(http:|https:)/
                  new_file_list_datum[:thumbnail_image] = my_thumbnail
                  new_file_list_datum[:t_file_type] = 'mp4'
                else
                  new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                  new_file_list_datum[:t_file_type] = 'png'
                end
                #          new_file_list_datum[:t_file_type] = 'mp4'
              else
                my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                if my_thumbnail.blank?
                  new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                elsif my_thumbnail =~ /(http:|https:)/
                  new_file_list_datum[:thumbnail_image] = my_thumbnail
                else
                  new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                end
                new_file_list_datum[:t_file_type] = 'pdf'
              end
            end # => end of if fn[:node_type] == NODE_DIRECTORY
            new_file_list_datum[:url] = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_FILE, my_hash_key
            new_file_list_datum[:file_size] = fn[:node_size]
            new_file_list_datum[:file_size_upper] = fn[:node_size_upper]
            #            new_file_list_datum[:file_exact_size] = fn[:node_size]
            new_file_list_datum[:file_version] = fn[:node_version]
            new_file_list_datum[:created_date] = fn[:ctime] == nil ? Time.now : fn[:ctime]
            new_file_list_datum[:creator] = SpinUserAttribute.get_user_name fn[:created_by]
            new_file_list_datum[:modifier] = SpinUserAttribute.get_user_name fn[:spin_uid]
            new_file_list_datum[:modified_date] = fn[:mtime] == nil ? Time.now : fn[:mtime]
            new_file_list_datum[:spin_updated_at] = fn[:spin_updated_at]
            new_file_list_datum[:spin_created_at] = fn[:spin_created_at]
            # new_file_list_datum[:modified_date] = fn[:updated_at]
            new_file_list_datum[:owner] = SpinUserAttribute.get_user_name fn[:spin_uid]
            new_file_list_datum[:ownership] = (fn[:spin_uid] == my_uid) ? "me" : "other"
            new_file_list_datum[:control_right] = (((SpinAccessControl.has_acl ssid, fn[:spin_node_hashkey]) & ACL_NODE_CONTROL) != 0 ? true : false) # ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_CONTROL) != 0? true : false
            new_file_list_datum[:dirty] = fn[:is_dirty_flag]
            new_file_list_datum[:open_status] = false
            new_file_list_datum[:description] = fn[:node_description]
            new_file_list_datum[:details] = fn[:details]

            # ロック状態更新
            if fn[:lock_uid] != my_uid && fn[:lock_uid] != -1
              # 他ユーザがロックしている場合は、ロックステータスの状態に関わらず排他ロックとする
              # →データ不整合時のデッドロック防止
              new_file_list_datum[:lock] = FSTAT_LOCKED_EXCLUSIVE
            else
              if fn[:lock_uid] == my_uid
                new_file_list_datum[:lock] = FSTAT_LOCKED
              else
                new_file_list_datum[:lock] = FSTAT_UNLOCKED
              end
            end

            if fn[:lock_uid] >= 0
              new_file_list_datum[:id_lc_by] = SpinUser.get_uname fn[:lock_uid]
              new_file_list_datum[:id_lc_name] = SpinUserAttribute.get_user_name fn[:lock_uid]
            else
              new_file_list_datum[:id_lc_by] = ""
              new_file_list_datum[:id_lc_name] = ""
            end
            if attr.present?
              new_file_list_datum[:title] = (attr['title'] ? attr['title'] : "")
              # new_file_list_datum[:type] = new_file_list_datum[:file_type]
              new_file_list_datum[:subtitle] = (attr['subtitle'] ? attr['subtitle'] : "")
              new_file_list_datum[:frame_size] = (attr['frame_size'] ? attr['frame_size'].to_s : "")
              new_file_list_datum[:duration] = (attr['duration'] ? attr['duration'] : "")
              new_file_list_datum[:producer] = (attr['producer'] ? attr['producer'] : "")
              #new_file_list_datum[:produced_date] = ( attr['produced_date'] ? attr['produced_date'].to_time : "-" )
              new_file_list_datum[:produced_date] = (attr['produced_date'] ? attr['produced_date'] : "")
              new_file_list_datum[:location] = (attr['location'] ? attr['location'] : "")
              new_file_list_datum[:cast] = (attr['cast'] ? attr['cast'] : "")
              new_file_list_datum[:client] = (attr['client'] ? attr['client'] : "")
              new_file_list_datum[:copyright] = (attr['copyright'] ? attr['copyright'] : "")
              new_file_list_datum[:music] = (attr['music'] ? attr['music'] : "")
              new_file_list_datum[:keyword] = (attr['keyword'] ? attr['keyword'] : "")
            else
              new_file_list_datum[:subtitle] = ""
              new_file_list_datum[:frame_size] = ""
              new_file_list_datum[:duration] = ""
              new_file_list_datum[:producer] = ""
              #new_file_list_datum[:produced_date] = ""
              new_file_list_datum[:produced_date] = "-"
              new_file_list_datum[:location] = ""
              new_file_list_datum[:cast] = ""
              new_file_list_datum[:client] = ""
              new_file_list_datum[:copyright] = ""
              new_file_list_datum[:music] = ""
              new_file_list_datum[:keyword] = ""
            end
          }
          #            unless new_file_list_datum.save # => save = update database
          new_file_list_datum.save # => save = update database
          if SpinNotifyControl.has_notification(ssid, folder_key, NODE_DIRECTORY)
            #                if fn[:notify_type] < 0 and new_file_list_datum[:file_type] != 'folder'
            if fn[:notify_type] < 0 and fn[:node_type] == NODE_FILE
              thr = Thread.new do
                if fn[:node_version] > 1 and fn[:notified_modification_at].to_time == SYSTEM_DEFAULT_TIMESTAMP_STRING.to_time
                  SpinNotifyControl.notify_modification(ssid, folder_key, fn[:spin_node_hashkey], new_file_list_datum[:url], domain_hash_key)
                else
                  SpinNotifyControl.notify_new(ssid, folder_key, fn[:spin_node_hashkey], new_file_list_datum[:url], domain_hash_key)
                end
              end
            end # => ne dof if fn[:notify_type] < 0 and new_file_list_datum[:file_type] != 'folder'
          end # => end of if SpinNotifyControl.has_notification(ssid, current_folder_key, NODE_DIRECTORY)
          return {:success => false, :status => ERROR_FAILED_TO_LOAD_FILE_LIST_REC, :total => -1, :errors => 'Failed to load file list record.'}
            #            end # => end of if
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :load_file_list_rec_again
          end
        end

      end # => end of transaction
    }

    return {:success => true, :status => INFO_LOAD_FILE_LIST_REC_SUCCESS, :result => node_key}
  end

  def self.fill_search_file_list_data_table ssid, file_list_nodes, current_folder_key, location
    # get current domain for the session 'ssid'
    # current_folder_key = SpinSession.readonly.find_by_spin_session_id ssid
    my_uid = SessionManager.get_uid(ssid)
    total = file_list_nodes.length

    ftype = ''
    saved_records = 0
    file_type_icons = $file_type_icons

    #    ActiveRecord::Base::lock_optimistically = false
    catch(:load_file_list_rec_again) {

      self.transaction do
        # clear search data
        sdata = self.where :session_id => ssid, :cont_location => location
        sdata.destroy_all

        #    FileDatum.transaction do
        #    FileDatum.transaction do
        file_list_nodes.each {|fn|
          begin
            attr = (fn[:node_attributes].length > 2 ? (JSON.parse fn[:node_attributes]) : nil)
            new_file_list_datum = FileDatum.new {|new_file_list_datum|
              new_file_list_datum[:session_id] = ssid
              r = Random.new
              my_hash_key = Security.hash_key_s(ssid + fn[:spin_node_hashkey] + location + r.rand.to_s)
              new_file_list_datum[:hash_key] = my_hash_key
              new_file_list_datum[:target_hash_key] = my_hash_key
              #            new_file_list_datum[:hash_key] = fn[:spin_node_hashkey]
              new_file_list_datum[:spin_node_hashkey] = fn[:spin_node_hashkey]
              new_file_list_datum[:folder_hash_key] = current_folder_key
              #            attr = ( fn[:node_attributes'] ? (JSON.parse fn[:node_attributes]) : '{ "key": "value" }' )
              new_file_list_datum[:file_name] = fn[:node_name]
              new_file_list_datum[:latest] = fn[:latest]
              new_file_list_datum[:file_readable_status] = SpinAccessControl.is_readable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
              new_file_list_datum[:file_writable_status] = SpinAccessControl.is_writable(ssid, fn[:spin_node_hashkey], ANY_TYPE)
              pn = SpinLocationManager.get_parent_node(fn)
              pkey = pn[:spin_node_hashkey]
              #      pkey = SpinLocationManager.get_parent_key(fn[:spin_node_hashkey], ANY_TYPE)
              new_file_list_datum[:folder_readable_status] = SpinAccessControl.is_readable(ssid, pkey, ANY_TYPE)
              new_file_list_datum[:folder_writable_status] = SpinAccessControl.is_writable(ssid, pkey, ANY_TYPE)
              # new_file_list_datum[:icon_image] = "file_type_icon/FolderDocument.png"
              new_file_list_datum[:cont_location] = location
              # new_file_list_datum[:file_type] = ( fn[:node_type] == NODE_DIRECTORY ? FOLDER_TYPE : fn[:node_name].split('.')[-1] )
              if fn[:node_type] == NODE_DIRECTORY
                new_file_list_datum[:file_type] = FOLDER_TYPE;
                new_file_list_datum[:icon_image] = "file_type_icon/FolderDocument.png"
                new_file_list_datum[:thumbnail_image] = "file_type_icon/FolderDocument.png"
                new_file_list_datum[:t_file_type] = 'png';
              else
                ftype = ''
                if fn[:node_name].include?('.')
                  ftype = fn[:node_name].split('.')[-1]
                end
                new_file_list_datum[:file_type] = ftype
                new_file_list_datum[:icon_image] = "file_type_icon/unknown.png"
                if file_type_icons.present?
                  file_type_icons.each {|key, value|
                    next if ftype.blank?
                    if /#{ftype}/i =~ key
                      new_file_list_datum[:icon_image] = value
                      break
                    end
                  }
                end
                c_type = self.get_content_type(ftype)
                if c_type == C_PICTURE_TYPE
                  my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                  if my_thumbnail.blank?
                    new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                  elsif my_thumbnail =~ /(http:|https:)/
                    new_file_list_datum[:thumbnail_image] = my_thumbnail
                  else
                    new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                  end
                  new_file_list_datum[:t_file_type] = 'png'
                elsif c_type == C_VIDEO_TYPE
                  my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_PROXY_MOVIE, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                  if my_thumbnail.blank?
                    new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                    new_file_list_datum[:t_file_type] = 'png'
                  elsif my_thumbnail =~ /(http:|https:)/
                    new_file_list_datum[:thumbnail_image] = my_thumbnail
                    new_file_list_datum[:t_file_type] = 'mp4'
                  else
                    new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                    new_file_list_datum[:t_file_type] = 'png'
                  end
                else
                  my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                  if my_thumbnail.blank?
                    new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                  elsif my_thumbnail =~ /(http:|https:)/
                    new_file_list_datum[:thumbnail_image] = my_thumbnail
                  else
                    new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                  end
                  new_file_list_datum[:t_file_type] = 'pdf'
                end
              end
              new_file_list_datum[:file_size] = fn[:node_size]
              new_file_list_datum[:file_size_upper] = fn[:node_size_upper]
              #            new_file_list_datum[:file_exact_size] = fn[:node_size]
              new_file_list_datum[:file_version] = fn[:node_version]
              new_file_list_datum[:created_date] = fn[:ctime] == nil ? Time.now : fn[:ctime]
              new_file_list_datum[:creator] = SpinUserAttribute.get_user_name fn[:created_by]
              new_file_list_datum[:modified_date] = fn[:mtime] == nil ? Time.now : fn[:mtime]
              new_file_list_datum[:spin_updated_at] = fn[:spin_updated_at]
              new_file_list_datum[:spin_created_at] = fn[:spin_created_at]
              # new_file_list_datum[:modified_date] = fn[:updated_at]
              new_file_list_datum[:modifier] = SpinUserAttribute.get_user_name fn[:spin_uid]
              new_file_list_datum[:owner] = SpinUserAttribute.get_user_name fn[:spin_uid]
              new_file_list_datum[:ownership] = (fn[:spin_uid] == my_uid) ? "me" : "other"
              new_file_list_datum[:control_right] = (((SpinAccessControl.has_acl ssid, fn[:spin_node_hashkey]) & ACL_NODE_CONTROL) != 0 ? true : false) # ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_CONTROL) != 0? true : false
              new_file_list_datum[:dirty] = fn[:is_dirty_flag]
              new_file_list_datum[:open_status] = false
              new_file_list_datum[:description] = fn[:node_description]
              new_file_list_datum[:url] = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_FILE, my_hash_key
              # TODO 仮にURLにパスを設定、テーブル変更後修正
              new_file_list_datum[:url] = fn[:virtual_path]

              # ロック状態更新
              if fn[:lock_uid] != my_uid && fn[:lock_uid] != -1
                # 他ユーザがロックしている場合は、ロックステータスの状態に関わらず排他ロックとする
                # →データ不整合時のデッドロック防止
                new_file_list_datum[:lock] = FSTAT_LOCKED_EXCLUSIVE
              else
                if fn[:lock_uid] == my_uid
                  new_file_list_datum[:lock] = FSTAT_LOCKED
                else
                  new_file_list_datum[:lock] = FSTAT_UNLOCKED
                end
              end

              if fn[:lock_uid] >= 0
                new_file_list_datum[:id_lc_by] = SpinUser.get_uname fn[:lock_uid]
                new_file_list_datum[:id_lc_name] = SpinUserAttribute.get_user_name fn[:lock_uid]
              else
                new_file_list_datum[:id_lc_by] = ""
                new_file_list_datum[:id_lc_name] = ""
              end
              if attr.present?
                new_file_list_datum[:title] = (attr['title'] ? attr['title'] : "")
                # new_file_list_datum[:type] = new_file_list_datum[:file_type]
                new_file_list_datum[:subtitle] = (attr['subtitle'] ? attr['subtitle'] : "")
                new_file_list_datum[:frame_size] = (attr['frame_size'] ? attr['frame_size'].to_s : "")
                new_file_list_datum[:duration] = (attr['duration'] ? attr['duration'] : "")
                new_file_list_datum[:producer] = (attr['producer'] ? attr['producer'] : "")
                #new_file_list_datum[:produced_date] = ( attr['produced_date'] ? attr['produced_date'].to_time : "-" )
                new_file_list_datum[:produced_date] = (attr['produced_date'] ? attr['produced_date'] : "")
                new_file_list_datum[:location] = (attr['location'] ? attr['location'] : "")
                new_file_list_datum[:cast] = (attr['cast'] ? attr['cast'] : "")
                new_file_list_datum[:client] = (attr['client'] ? attr['client'] : "")
                new_file_list_datum[:copyright] = (attr['copyright'] ? attr['copyright'] : "")
                new_file_list_datum[:music] = (attr['music'] ? attr['music'] : "")
                new_file_list_datum[:keyword] = (attr['keyword'] ? attr['keyword'] : "")
                #              new_file_list_datum[:description] = ( attr['description'] ? attr['description'] : "" )
              else
                new_file_list_datum[:subtitle] = ""
                new_file_list_datum[:frame_size] = ""
                new_file_list_datum[:duration] = ""
                new_file_list_datum[:producer] = ""
                #new_file_list_datum[:produced_date] = "-"
                new_file_list_datum[:produced_date] = ""
                new_file_list_datum[:location] = ""
                new_file_list_datum[:cast] = ""
                new_file_list_datum[:client] = ""
                new_file_list_datum[:copyright] = ""
                new_file_list_datum[:music] = ""
                new_file_list_datum[:keyword] = ""
                #              new_file_list_datum[:description] = ""
              end
            }
            if new_file_list_datum.save # => save = update database
              saved_records += 1
            else
              break
            end # => end of if
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :load_file_list_rec_again
          end

        } # =>  end of folder_tree_nodes.each
      end # => end of transaction
    }
    #    end # => end of transaction
    #    end # end of transaction
    # printf ">> number of records saved : "
    # pp saved_records
    return {:success => true, :status => true, :total => total, :result => saved_records}
  end

  def self.get_search_file_list_display_data sid, cont_location, offset, limit
    file_list = []
    rethash = Hash.new
    rethash[:success] = true
    rethash[:total] = 0
    rethash[:start] = offset
    rethash[:limit] = limit
    rethash[:result] = 0
    rethash[:display_object] = []
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:get_search_file_list_display_data_again) {
      FileDatum.transaction do
        file_list = self.limit(limit).offset(offset).where(["session_id = >? AND cont_location = ?", sid, cont_location]).order("file_name ASC")
        file_list_all = self.where(["session_id = >? AND cont_location = ?", sid, cont_location]).order("file_name ASC")
        rethash[:total] = file_list_all.length
        file_list.each {|fl|
          begin
            fl[:created_at] = (fl[:spin_created_at] == nil ? fl[:spin_updated_at] : fl[:spin_created_at])
            fl[:updated_at] = fl[:spin_updated_at]
            fl.save
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :get_search_file_list_display_data_again
          end
        }
      end # => end of transaction
    } # => end of catch block
    rethash[:result] = rethash[:total]
    rethash[:display_object] = file_list
    return rethash
  end

  # => end of get_file_list_display_data

  def self.get_content_type(ftype)
    ret = C_OTHER_TYPE
    case ftype
    when 'jpg', 'JPG', 'jpeg', 'JPEG', 'tif', 'TIF', 'tiff', 'TIFF', 'pict', 'png', 'PNG', 'mp3', 'MP3', 'm4a', 'M4A'
      ret = C_PICTURE_TYPE
    when 'mov', 'MOV', 'm4v', 'M4V', 'mp4', 'MP4', 'avi', 'AVI', 'wmv', 'WMV', 'mpeg', 'MPEG', 'qt', 'QT', 'ogg'
      ret = C_VIDEO_TYPE
    end
    return ret
  end

  def self.xget_content_type(ftype)
    case ftype
    when 'jpg'
      return C_PICTURE_TYPE
    when 'JPG'
      return C_PICTURE_TYPE
    when 'jpeg'
      return C_PICTURE_TYPE
    when 'JPEG'
      return C_PICTURE_TYPE
    when 'tif'
      return C_PICTURE_TYPE
    when 'tiff'
      return C_PICTURE_TYPE
    when 'TIF'
      return C_PICTURE_TYPE
    when 'TIFF'
      return C_PICTURE_TYPE
    when 'xls'
      return C_OTHER_TYPE
    when 'xlsx'
      return C_OTHER_TYPE
    when 'doc'
      return C_OTHER_TYPE
    when 'docx'
      return C_OTHER_TYPE
    when 'ppt'
      return C_OTHER_TYPE
    when 'pptx'
      return C_OTHER_TYPE
    when 'pdf'
      return C_OTHER_TYPE
    when 'psd'
      return C_OTHER_TYPE
    when 'ai'
      return C_OTHER_TYPE
    when 'eps'
      return C_OTHER_TYPE
    when 'pict'
      return C_PICTURE_TYPE
    when 'bmp'
      return C_PICTURE_TYPE
    when 'png'
      return C_PICTURE_TYPE
    when 'mp4', 'ogg', 'mov', 'avi' # => mp4,ogg,mov,avi
      return C_VIDEO_TYPE
    when 'key', 'kth', 'apxl', 'knt', 'pages', 'numbers'
      return C_OTHER_TYPE
    else
      return C_OTHER_TYPE
    end
    return C_OTHER_TYPE
  end

  # => end of self.get_content_type ftype

  def self.remove_file_rec sid, location, node_hash_key
    cns = []
    #    FileDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    #    ActiveRecord::Base::lock_optimistically = false

    catch(:remove_file_rec_again) {
      FileDatum.transaction do
        begin
          if location == LOCATION_ANY
            #        self.find_by_sql("SELECT id FROM folder_data WHERE session_id = \'#{sid}\' AND spin_node_hashkey = \'#{node_hash_key}\' FOR UPDATE;")
            cns = self.where(["session_id = ? AND spin_node_hashkey = ?", sid, node_hash_key])
          else
            #        self.find_by_sql("SELECT id FROM folder_data WHERE session_id = \'#{sid}\' AND cont_location = \'#{location}\' FOR UPDATE;")
            cns = self.where(["session_id = ? AND cont_location = ? AND spin_node_hashkey = ?", sid, location, node_hash_key])
          end
          cns.each {|cn|
            begin
              cn.destroy
            rescue ActiveRecord::StaleObjectError
              FileManager.logger(sid, 'file record is already removed')
            end
          }
        rescue ActiveRecord::StaleObjectError
          return nil
        end
      end
    }
  end

  def self.clear_search_file_list_display_data ssid, location = 'search_result'
    #    FileDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    #    ActiveRecord::Base::lock_optimistically = false

    catch(:clear_search_file_list_display_data_again) {
      FileDatum.transaction do
        begin
          #      self.find_by_sql("SELECT id FROM folder_data WHERE session_id = \'#{ssid}\' AND cont_location = \'#{location}\' FOR UPDATE;")
          recs = self.where :session_id => ssid, :cont_location => location
          if recs.length > 0
            recs.destroy_all
          end
        rescue ActiveRecord::StaleObjectError
          return nil
        end
      end
    }
  end

  # => end of FileDatum.clear_search_file_list_display_data ssid, 'search_result'

  def self.file_force_list_data_table ssid, last_ssid, my_uid, location, current_folder_key, mobile_list = false
    # Is it dirty?
    #    is_dirty_list = FolderDatum.is_dirty_folder(ssid, location, current_folder_key, true)

    # get location of currentg directory
    cd_loc = SpinLocationManager.key_to_location current_folder_key, NODE_DIRECTORY

    # get spin_domain
    dom = FolderDatum.select("domain_hash_key").find_by_session_id_and_cont_location_and_spin_node_hashkey(ssid, location, current_folder_key)
    if dom.present?
      domain_hash_key = dom[:domain_hash_key]
    else
      domain_hash_key = SpinUser.get_default_domain(ssid)
    end

    acls = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    acls_p = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    pkey = ''

    file_list_nodes = []
    file_list_nodes = SpinNode.readonly.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND in_trash_flag = false AND is_void = false AND is_pending = false", SPIN_NODE_VTREE, cd_loc[X], cd_loc[Y] + 1]).order("node_name ASC, node_version DESC") # => includes files and directories in the current directory

    if file_list_nodes.length == 0
      return
    end

    folder_hash_key = current_folder_key

    # build FolderData
    file_type_icons = $file_type_icons
    pkey_aquired = false
    #    FileDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    #    ActiveRecord::Base::lock_optimistically = false

    catch(:file_force_list_data_table_again) {

      FileDatum.transaction do
        file_list_nodes.each {|fn|
          begin
            next if fn[:node_name] == nil
            if my_uid == 0
              acls = {:user => ACL_NODE_SUPERUSER_ACCESS, :group => ACL_NODE_SUPERUSER_ACCESS, :world => fn[:spin_world_access_right]}
            else
              acls = SpinAccessControl.has_acl_values ssid, fn[:spin_node_hashkey], ANY_TYPE
            end
            unless pkey_aquired
              pn = SpinLocationManager.get_parent_node(fn)
              pkey = pn[:spin_node_hahskey]
              acls_p = SpinAccessControl.has_acl_values(ssid, pkey, ANY_TYPE)
              pkey_aquired = true
            end
            if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS or acls[:world] > ACL_NODE_NO_ACCESS # => match!
              file_list_recs = self.where(["spin_node_hashkey = ? AND session_id = ? AND cont_location = ? AND folder_hash_key = ?", fn[:spin_node_hashkey], ssid, location, folder_hash_key]).order("file_version DESC")

              if file_list_recs.length > 0 # => there is file list data
                file_list_recs.each_with_index {|file_list_rec, idx|
                  unless idx == 0
                    file_list_rec.destroy
                    next
                  end

                  begin
                    file_list_rec[:latest] = true
                    attr = (fn[:node_attributes].length > 2 ? (JSON.parse fn[:node_attributes]) : nil)
                    file_list_rec[:file_name] = fn[:node_name]
                    file_list_rec[:latest] = fn[:latest]
                    file_list_rec[:file_readable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
                    file_list_rec[:file_writable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                    file_list_rec[:folder_readable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
                    file_list_rec[:file_writable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                    file_list_rec[:cont_location] = location
                    if fn[:node_type] == NODE_DIRECTORY
                      file_list_rec[:file_type] = FOLDER_TYPE;
                      file_list_rec[:icon_image] = "file_type_icon/FolderDocument.png"
                      file_list_rec[:thumbnail_image] = "file_type_icon/FolderDocument.png"
                      file_list_rec[:t_file_type] = 'png';
                    else
                      ftype = ''
                      if fn[:node_name].include?('.')
                        ftype = fn[:node_name].split('.')[-1]
                      end
                      file_list_rec[:file_type] = ftype
                      file_list_rec[:icon_image] = "file_type_icon/unknown.png"
                      if file_type_icons.present?
                        file_type_icons.each {|key, value|
                          next if ftype.blank?
                          if /#{ftype}/i =~ key
                            file_list_rec[:icon_image] = value
                            break
                          end
                        }
                      end
                      c_type = self.get_content_type(ftype)
                      if c_type == C_PICTURE_TYPE
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, file_list_rec[:hash_key] # SpinUrl.get_url(file_list_rec[:hash_key])
                        if my_thumbnail.blank?
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        elsif my_thumbnail =~ /(http:|https:)/
                          file_list_rec[:thumbnail_image] = my_thumbnail
                        else
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        end
                        file_list_rec[:t_file_type] = 'png'
                      elsif c_type == C_VIDEO_TYPE
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_PROXY_MOVIE, file_list_rec[:hash_key] # SpinUrl.get_url(file_list_rec[:hash_key])
                        if my_thumbnail.blank?
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                          file_list_rec[:t_file_type] = 'png'
                        elsif my_thumbnail =~ /(http:|https:)/
                          file_list_rec[:thumbnail_image] = my_thumbnail
                          file_list_rec[:t_file_type] = 'mp4'
                        else
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                          file_list_rec[:t_file_type] = 'png'
                        end
                      else
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, file_list_rec[:hash_key] # SpinUrl.get_url(file_list_rec[:hash_key])
                        if my_thumbnail.blank?
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        elsif my_thumbnail =~ /(http:|https:)/
                          file_list_rec[:thumbnail_image] = my_thumbnail
                        else
                          file_list_rec[:thumbnail_image] = file_list_rec[:icon_image]
                        end
                        file_list_rec[:t_file_type] = 'pdf'
                      end
                    end
                    file_list_rec[:spin_node_hashkey] = fn[:spin_node_hashkey]
                    file_list_rec[:file_size] = fn[:node_size]
                    file_list_rec[:file_size_upper] = fn[:node_size_upper]
                    file_list_rec[:url] = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_FILE, file_list_rec[:hash_key] # SpinUrl.get_url(file_list_rec[:hash_key])
                    file_list_rec[:file_version] = fn[:node_version]
                    file_list_rec[:creator] = SpinUserAttribute.get_user_name fn[:spin_uid]
                    file_list_rec[:modified_date] = fn[:mtime]
                    file_list_rec[:spin_updated_at] = fn[:spin_updated_at]
                    file_list_rec[:spin_created_at] = fn[:spin_created_at]
                    file_list_rec[:modifier] = SpinUserAttribute.get_user_name fn[:updated_by]
                    file_list_rec[:owner] = SpinUserAttribute.get_user_name fn[:spin_uid]
                    file_list_rec[:ownership] = (fn[:spin_uid] == my_uid) ? "me" : "other"
                    file_list_rec[:control_right] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_CONTROL) != 0 ? true : false) # (((SpinAccessControl.has_acl ssid, fn[:spin_node_hashkey])&ACL_NODE_CONTROL) != 0 ? true : false ) # ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_CONTROL) != 0? true : false
                    file_list_rec[:dirty] = true # => may be
                    file_list_rec[:description] = fn[:node_description]
                    file_list_rec[:details] = fn[:details]

                    # ロック状態更新
                    if fn[:lock_uid] != my_uid && fn[:lock_uid] != -1
                      # 他ユーザがロックしている場合は、ロックステータスの状態に関わらず排他ロックとする
                      # →データ不整合時のデッドロック防止
                      file_list_rec[:lock] = FSTAT_LOCKED_EXCLUSIVE
                    else
                      if fn[:lock_uid] == my_uid
                        file_list_rec[:lock] = FSTAT_LOCKED
                      else
                        file_list_rec[:lock] = FSTAT_UNLOCKED
                      end
                    end

                    if fn[:lock_uid] >= 0
                      file_list_rec[:id_lc_by] = SpinUser.get_uname fn[:lock_uid]
                      file_list_rec[:id_lc_name] = SpinUserAttribute.get_user_name fn[:lock_uid]
                    else
                      file_list_rec[:id_lc_by] = ""
                      file_list_rec[:id_lc_name] = ""
                    end
                    if attr.present?
                      file_list_rec[:title] = (attr['title'] ? attr['title'] : "")
                      file_list_rec[:subtitle] = (attr['subtitle'] ? attr['subtitle'] : "")
                      file_list_rec[:frame_size] = (attr['frame_size'] ? attr['frame_size'].to_s : "")
                      file_list_rec[:duration] = (attr['duration'] ? attr['duration'] : "")
                      file_list_rec[:producer] = (attr['producer'] ? attr['producer'] : "")
                      file_list_rec[:produced_date] = (attr['produced_date'] ? attr['produced_date'] : "")
                      file_list_rec[:location] = (attr['location'] ? attr['location'] : "")
                      file_list_rec[:cast] = (attr['cast'] ? attr['cast'] : "")
                      file_list_rec[:client] = (attr['client'] ? attr['client'] : "")
                      file_list_rec[:copyright] = (attr['copyright'] ? attr['copyright'] : "")
                      file_list_rec[:music] = (attr['music'] ? attr['music'] : "")
                      file_list_rec[:keyword] = (attr['keyword'] ? attr['keyword'] : "")
                    else
                      file_list_rec[:title] = ""
                      file_list_rec[:subtitle] = ""
                      file_list_rec[:frame_size] = ""
                      file_list_rec[:duration] = ""
                      file_list_rec[:producer] = ""
                      file_list_rec[:produced_date] = ""
                      file_list_rec[:location] = ""
                      file_list_rec[:cast] = ""
                      file_list_rec[:client] = ""
                      file_list_rec[:copyright] = ""
                      file_list_rec[:music] = ""
                      file_list_rec[:keyword] = ""
                    end

                    file_list_rec.save # => save = update database
                  rescue ActiveRecord::StaleObjectError
                    sleep(AR_RETRY_WAIT_MSEC)
                    throw :file_force_list_data_table_again
                  end
                }
              else # => no file rec's, new node! uploaded, copied or moved.
                attr = (fn[:node_attributes].length > 2 ? (JSON.parse fn[:node_attributes]) : nil)
                #              self.find_by_sql('LOCK TABLE file_data IN ROW EXCLUSIVE MODE;')
                begin
                  new_file_list_datum = FileDatum.new {|new_file_list_datum|
                    new_file_list_datum[:session_id] = ssid
                    r = Random.new
                    my_hash_key = Security.hash_key_s(ssid + fn[:spin_node_hashkey] + location + r.rand.to_s)
                    new_file_list_datum[:hash_key] = my_hash_key
                    new_file_list_datum[:spin_node_hashkey] = fn[:spin_node_hashkey]
                    new_file_list_datum[:folder_hash_key] = folder_hash_key
                    new_file_list_datum[:domain_hash_key] = domain_hash_key
                    new_file_list_datum[:file_name] = fn[:node_name]
                    new_file_list_datum[:latest] = fn[:latest]
                    new_file_list_datum[:file_readable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
                    new_file_list_datum[:file_writable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                    new_file_list_datum[:folder_readable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
                    new_file_list_datum[:file_writable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
                    new_file_list_datum[:cont_location] = location
                    if fn[:node_type] == NODE_DIRECTORY
                      new_file_list_datum[:file_type] = FOLDER_TYPE;
                      new_file_list_datum[:icon_image] = "file_type_icon/FolderDocument.png"
                      new_file_list_datum[:thumbnail_image] = "file_type_icon/FolderDocument.png"
                      new_file_list_datum[:t_file_type] = 'png';
                    else
                      ftype = ''
                      if fn[:node_name].include?('.')
                        ftype = fn[:node_name].split('.')[-1]
                      end
                      new_file_list_datum[:file_type] = ftype
                      new_file_list_datum[:icon_image] = "file_type_icon/unknown.png"
                      if file_type_icons.present?
                        file_type_icons.each {|key, value|
                          next if ftype.blank?
                          if /#{ftype}/i =~ key
                            new_file_list_datum[:icon_image] = value
                            break
                          end
                        }
                      end
                      c_type = self.get_content_type(ftype)
                      if c_type == C_PICTURE_TYPE
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                        if my_thumbnail.blank?
                          new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                        elsif my_thumbnail =~ /(http:|https:)/
                          new_file_list_datum[:thumbnail_image] = my_thumbnail
                        else
                          new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                        end
                        new_file_list_datum[:t_file_type] = 'png'
                      elsif c_type == C_VIDEO_TYPE
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_PROXY_MOVIE, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                        if my_thumbnail.blank?
                          new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                          new_file_list_datum[:t_file_type] = 'png'
                        elsif my_thumbnail =~ /(http:|https:)/
                          new_file_list_datum[:thumbnail_image] = my_thumbnail
                          new_file_list_datum[:t_file_type] = 'mp4'
                        else
                          new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                          new_file_list_datum[:t_file_type] = 'png'
                        end
                      else
                        my_thumbnail = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_THUMBNAIL, my_hash_key # SpinUrl.get_url(new_file_list_datum[:hash_key])
                        if my_thumbnail.blank?
                          new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                        elsif my_thumbnail =~ /(http:|https:)/
                          new_file_list_datum[:thumbnail_image] = my_thumbnail
                        else
                          new_file_list_datum[:thumbnail_image] = new_file_list_datum[:icon_image]
                        end
                        new_file_list_datum[:t_file_type] = 'pdf'
                      end
                    end
                    new_file_list_datum[:url] = SpinUrl.generate_url ssid, fn[:spin_node_hashkey], fn[:node_name], NODE_FILE, my_hash_key
                    new_file_list_datum[:file_size] = fn[:node_size]
                    new_file_list_datum[:file_size_upper] = fn[:node_size_upper]
                    new_file_list_datum[:file_version] = fn[:node_version]
                    new_file_list_datum[:created_date] = fn[:ctime] == nil ? Time.now : fn[:ctime]
                    new_file_list_datum[:creator] = SpinUserAttribute.get_user_name fn[:created_by]
                    new_file_list_datum[:modified_date] = fn[:mtime] == nil ? Time.now : fn[:mtime]
                    new_file_list_datum[:spin_updated_at] = fn[:spin_updated_at]
                    new_file_list_datum[:spin_created_at] = fn[:spin_created_at]
                    new_file_list_datum[:modifier] = SpinUserAttribute.get_user_name fn[:spin_uid]
                    new_file_list_datum[:owner] = SpinUserAttribute.get_user_name fn[:spin_uid]
                    new_file_list_datum[:ownership] = (fn[:spin_uid] == my_uid) ? "me" : "other"
                    new_file_list_datum[:control_right] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_CONTROL) != 0 ? true : false)
                    new_file_list_datum[:dirty] = fn[:is_dirty_flag]
                    new_file_list_datum[:open_status] = false
                    new_file_list_datum[:description] = fn[:node_description]
                    new_file_list_datum[:details] = fn[:details]

                    # ロック状態更新
                    if fn[:lock_uid] != my_uid && fn[:lock_uid] != -1
                      # 他ユーザがロックしている場合は、ロックステータスの状態に関わらず排他ロックとする
                      # →データ不整合時のデッドロック防止
                      new_file_list_datum[:lock] = FSTAT_LOCKED_EXCLUSIVE
                    else
                      if fn[:lock_uid] == my_uid
                        new_file_list_datum[:lock] = FSTAT_LOCKED
                      else
                        new_file_list_datum[:lock] = FSTAT_UNLOCKED
                      end
                    end

                    if fn[:lock_uid] >= 0
                      new_file_list_datum[:id_lc_by] = SpinUser.get_uname fn[:lock_uid]
                      new_file_list_datum[:id_lc_name] = SpinUserAttribute.get_user_name fn[:lock_uid]
                    else
                      new_file_list_datum[:id_lc_by] = ""
                      new_file_list_datum[:id_lc_name] = ""
                    end
                    if attr.present?
                      new_file_list_datum[:title] = (attr['title'] ? attr['title'] : "")
                      new_file_list_datum[:subtitle] = (attr['subtitle'] ? attr['subtitle'] : "")
                      new_file_list_datum[:frame_size] = (attr['frame_size'] ? attr['frame_size'].to_s : "")
                      new_file_list_datum[:duration] = (attr['duration'] ? attr['duration'] : "")
                      new_file_list_datum[:producer] = (attr['producer'] ? attr['producer'] : "")
                      new_file_list_datum[:produced_date] = (attr['produced_date'] ? attr['produced_date'] : "")
                      new_file_list_datum[:location] = (attr['location'] ? attr['location'] : "")
                      new_file_list_datum[:cast] = (attr['cast'] ? attr['cast'] : "")
                      new_file_list_datum[:client] = (attr['client'] ? attr['client'] : "")
                      new_file_list_datum[:copyright] = (attr['copyright'] ? attr['copyright'] : "")
                      new_file_list_datum[:music] = (attr['music'] ? attr['music'] : "")
                      new_file_list_datum[:keyword] = (attr['keyword'] ? attr['keyword'] : "")
                    else
                      new_file_list_datum[:subtitle] = ""
                      new_file_list_datum[:frame_size] = ""
                      new_file_list_datum[:duration] = ""
                      new_file_list_datum[:producer] = ""
                      new_file_list_datum[:produced_date] = ""
                      new_file_list_datum[:location] = ""
                      new_file_list_datum[:cast] = ""
                      new_file_list_datum[:client] = ""
                      new_file_list_datum[:copyright] = ""
                      new_file_list_datum[:music] = ""
                      new_file_list_datum[:keyword] = ""
                    end
                  }
                  new_file_list_datum.save # => save = update database
                  if SpinNotifyControl.has_notification(ssid, current_folder_key, NODE_DIRECTORY)
                    if fn[:notify_type] < 0 and fn[:node_type] == NODE_FILE
                      thr = Thread.new do
                        if fn[:node_version] > 1 and fn[:notified_modification_at].to_time == SYSTEM_DEFAULT_TIMESTAMP_STRING.to_time
                          SpinNotifyControl.notify_modification(ssid, current_folder_key, fn[:spin_node_hashkey], new_file_list_datum[:url], domain_hash_key)
                        else
                          SpinNotifyControl.notify_new(ssid, current_folder_key, fn[:spin_node_hashkey], new_file_list_datum[:url], domain_hash_key)
                        end
                      end
                    end # => ne dof if fn[:notify_type] < 0 and new_file_list_datum[:file_type] != 'folder'
                  end # => end of if SpinNotifyControl.has_notification(ssid, current_folder_key, NODE_DIRECTORY)
                rescue ActiveRecord::StaleObjectError
                  sleep(AR_RETRY_WAIT_MSEC)
                  throw :file_force_list_data_table_again
                end
              end # => end of if new_file_list_datum
            end # => end of if acls[:user
          end
        } # =>  end of folder_tree_nodes.each
      end # => end of transaction
    } # => end of catch block

    SessionManager.set_location_clean(ssid, location, true)
    return
  end

  def self.fill_force_file_list ssid, location, my_current_folder, mobile_list = false
    # gproduced_dateet uid and gid
    my_uid = SessionManager.get_uid ssid
    # get current domain at the location
    session_rec = {}
    session_rec = SpinSession.readonly.find_by_spin_session_id ssid

    logger.debug location
    logger.debug session_rec

    last_session = SessionManager.get_last_session ssid
    rethash = Hash.new
    # search spin_folders and spin_access_control, and fill domain table
    rethash = file_force_list_data_table ssid, last_session, my_uid, location, my_current_folder, mobile_list
    return rethash
  end # => end of fill_file_lists

end
