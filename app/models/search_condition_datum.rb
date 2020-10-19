# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'const/spin_types'
require 'tasks/session_management'
require 'tasks/security'
require 'pg'
require 'pp'
require 'nkf'

class SearchConditionDatum < ActiveRecord::Base
  include Vfs
  include Acl
  include Stat
  include Types

  attr_accessor :session_id, :target_checked_out_by_me, :target_created_by_me, :target_created_date_begin, :target_created_date_end, :target_creator, :target_file_name, :target_file_size_max, :target_file_size_min, :target_folder, :target_locked_by_me, :target_max_display_files, :target_modified_by_me, :target_modified_date_begin, :target_modified_date_end, :target_modifier, :target_subfolder, :property, :target_check_str_size, :target_check_str_char

  def self.search_files sid, conditions, opt_conditions
    my_uid = SessionManager.get_uid(sid)
    #      search_sid = paramshash[:session_id]
    #      conditions[:target_file_name] = paramshash[:target_file_name]
    #      conditions[:folder_hash_key] = paramshash[:hash_key]
    #      conditions[:target_subfolder] = paramshash[:target_subfolder] # => bool : indicates search subfolders if true, or this folder only
    #      conditions[:folder_name] = paramshash[:text]
    #      conditions[:target_modifier] = paramshash[:target_modifier]

    queries = []
    
    query_for_target_file_name = ''
    unless conditions[:target_file_name].blank?
      query_for_target_file_name = "node_name LIKE \'%#{conditions[:target_file_name]}%\'"
    end

    unless query_for_target_file_name.blank?
      if conditions[:target_check_str_size] == true and conditions[:target_check_str_char] == true
      elsif conditions[:target_check_str_size] == true 
        #        # 全角半角区別なし
        chkStr = NKF::nkf( '-WwZ0', conditions[:target_file_name] ) 
        query_for_target_file_name = "translate(node_name, '－０１２３４５６７８９ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ　','-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ' ) LIKE \'%#{chkStr}%\'"      
      elsif conditions[:target_check_str_char] == true 
        # 大文字小文字区別なし
        query_for_target_file_name = "upper(node_name) LIKE \'%#{conditions[:target_file_name].upcase}%\'"
      else 
        # 大文字小文字・全角半角区別なし
        chkStr = NKF::nkf( '-WwZ0', conditions[:target_file_name] ) 
        query_for_target_file_name = "translate(upper(node_name), '－０１２３４５６７８９ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ　','-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ' ) LIKE \'%#{chkStr.upcase}%\'"      
      end
    end
    
    unless query_for_target_file_name.blank?
      queries.push query_for_target_file_name
    end
    
    query_for_updated_by = ''
    unless conditions[:target_modifier].blank? or conditions[:target_modifier].blank?
      updated_by_uid = SpinUser.get_uid(conditions[:target_modifier])
      if updated_by_uid != nil
        if conditions[:target_modified_by_me] == true
          query_for_updated_by = "( updated_by = #{updated_by_uid} OR updated_by = #{my_uid} )"
        else
          query_for_updated_by = "updated_by = #{updated_by_uid}"
        end
      end
    else
      if conditions[:target_modified_by_me] == true
        query_for_updated_by = "updated_by = #{my_uid}"
      end
    end

    unless query_for_updated_by.blank?
      queries.push query_for_updated_by
    end
    
    query_for_created_by = ''
    unless conditions[:target_creator].blank? or conditions[:target_creator].blank?
      created_by_uid = SpinUser.get_uid(conditions[:target_creator])
      if created_by_uid != nil
        if conditions[:target_created_by_me] == true
          query_for_created_by = "( created_by = #{created_by_uid} OR created_by = #{my_uid} )"
        else
          query_for_created_by = "created_by = #{created_by_uid}"
        end
      end
    else
      if conditions[:target_created_by_me] == true
        query_for_created_by = "created_by = #{my_uid}"
      end
    end
    
    unless query_for_created_by.blank?
      queries.push query_for_created_by
    end
    
    query_for_opt_conditions = '' # => description
    unless opt_conditions.blank?
      #if opt_conditions[0][:value] != nil and opt_conditions[0][:value].blank? != true
      #  pat = opt_conditions[0][:value]
      #        pat = opt_conditions[0][:value].to_json.gsub(/"/,'')
      #  query_for_opt_conditions = "node_description LIKE \'%#{pat}%\'"
      #        query_for_opt_conditions = "node_attributes LIKE \'%\"description\":\"%#{pat}%\'"
      #        query_for_opt_conditions = "node_attributes LIKE \'%#{pat}%\'"
      #end
      #
      # Add by imai for memo search 2015/1/14
      #opt_conditions_number = opt_conditions.length 
      opt_conditions_first = 0
      opt_conditions.each do |opt|
        fname_pat = opt[:field_name]
        value_pat = opt[:value]
        unless value_pat.blank?
          if opt_conditions_first == 0            
            query_for_opt_conditions = "#{fname_pat} LIKE \'%#{value_pat}%\'"
          else
            #query_for_opt_conditions = query_for_opt_conditions + "and #{fname_pat} LIKE \'%#{value_pat}%\'"
            query_for_opt_conditions = query_for_opt_conditions + "or #{fname_pat} LIKE \'%#{value_pat}%\'"
          end
          opt_conditions_first = 1
        end
      end
    end
    
    unless query_for_opt_conditions.blank?
      queries.push query_for_opt_conditions
    end
    
    query_for_lock_uid = ''
    unless conditions[:locked_by_me] == false
      query_for_lock_uid = "lock_uid = #{my_uid}"
    end
    
    unless query_for_lock_uid.blank?
      queries.push query_for_lock_uid
    end
    
    query_for_created_date = ''
    unless conditions[:target_created_date_begin].blank? and conditions[:target_created_date_end].blank?
      if conditions[:target_created_date_begin].blank?
        timestamp_target_created_date_end = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_created_date_end])
        query_for_created_date = "spin_created_at <= to_timestamp(#{timestamp_target_created_date_end + 1.day - 1.second})"
      elsif conditions[:target_created_date_end].blank?
        timestamp_target_created_date_begin = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_created_date_begin])
        query_for_created_date = "spin_created_at >= to_timestamp(#{timestamp_target_created_date_begin})"
      else
        timestamp_target_created_date_end = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_created_date_end])
        timestamp_target_created_date_begin = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_created_date_begin])
        query_for_created_date = "( spin_created_at >= to_timestamp(#{timestamp_target_created_date_begin}) AND spin_created_at <= to_timestamp(#{timestamp_target_created_date_end + 1.day - 1.second}) )"
      end
    end
    
    unless query_for_created_date.blank?
      queries.push query_for_created_date
    end
    
    query_for_spin_updated_at = ''
    unless conditions[:target_modified_date_begin].blank? and conditions[:target_modified_date_end].blank?
      if conditions[:target_modified_date_begin].blank?
        timestamp_target_modified_date_end = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_modified_date_end])
        query_for_spin_updated_at = "spin_updated_at <= to_timestamp(#{timestamp_target_modified_date_end + 1.day - 1.second})"
      elsif conditions[:target_modified_date_end].blank?
        timestamp_target_modified_date_begin = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_modified_date_begin])
        query_for_spin_updated_at = "spin_updated_at >= to_timestamp(#{timestamp_target_modified_date_begin})"
      else
        timestamp_target_modified_date_end = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_modified_date_end])
        timestamp_target_modified_date_begin = DatabaseUtility::VirtualFileSystemUtility.convert_to_timestamp(conditions[:target_modified_date_begin])
        query_for_spin_updated_at = "( spin_updated_at >= to_timestamp(#{timestamp_target_modified_date_begin}) AND spin_updated_at <= to_timestamp(#{timestamp_target_modified_date_end + 1.day - 1.second}) )"
      end
    end
    
    unless query_for_spin_updated_at.blank?
      queries.push query_for_spin_updated_at
    end
    
    my_query = ''
    queries.each_with_index {|q,idx|
      if idx == 0
        my_query = q
      else
        my_query = my_query + ' AND ' + q
      end
    }
    
    printf ">> my_query = %s\n", my_query
    
    if my_query.blank?
      return []
    end
    # basic search
    # => search by basic attributes from spin_nodes
    # 
    search_list = Array.new
    nodes = Array.new
    max_depth = -1
    search_vpath = SpinNode.get_vpath(conditions[:folder_hash_key])
    search_vpath.gsub!(/\'/,'\'\'')
    query_for_search_nodes = " AND virtual_path LIKE \'#{search_vpath}/%\' AND node_type = #{NODE_FILE}"
    #    loc = SpinLocationManager.key_to_location(conditions[:folder_hash_key], NODE_DIRECTORY)
    if conditions[:target_subfolder] == true # => search subfolders
      #      search_nodes = SpinNode.readonly.select("spin_node_hashkey").where("#{query_for_search_nodes}")
      #      search_nodes_keys = []
      #      search_nodes.each {|s|
      #        search_nodes_keys.push s[:spin_node_hashkey]
      #      }
      #      rn = SpinNode.find_by_spin_node_hashkey conditions[:folder_hash_key]
      #      search_list = SpinLocationManager.get_sub_tree_nodes(sid, loc, max_depth)
      #      search_list.insert(0, rn)
      #      sql_params = { :sql => '', :params => [ {} ]}
      #      search_list.each { |snode|  
      # Now I only support search by file name!
      conditions[:node_type] = NODE_FILE
      #        # exact match first!
      #        tnodes = SpinNode.where :node_type => NODE_FILE, :node_name => conditions[:target_file_name]
      #        tnodes.each {|tn|
      #          if SpinAccessControl.is_accessible_node(sid, tn[:spin_node_hashkey])
      #            nodes.append tn
      #          end
      #        }
      # match by LIKE
      #        qstr = conditions[:target_file_name]
        
      #  build query
      #        base_query = "node_name LIKE \'%#{qstr}%\' AND node_x_pr_coord = ? AND node_y_coord = ?"
      # => end of build query
      #         
      q_conditions = my_query + query_for_search_nodes + ' AND latest = true AND is_void = false AND is_pending = false AND in_trash_flag = false'
      #        q_conditions = my_query + ' AND node_x_pr_coord = ' + snode[:node_x_coord].to_s + ' AND node_y_coord = ' + (snode[:node_y_coord]+1).to_s + ' AND node_type = ' + NODE_FILE.to_s + ' AND latest = true AND is_void = false AND is_pending = false AND in_trash_flag = false'
      printf ">> q_conditions = [%s]\n", q_conditions
      tlnodes = SpinNode.where("#{q_conditions}")
      #        tlnodes = SpinNode.where( "#{my_query} AND node_x_pr_coord = ? AND node_y_coord = ?", snode[:node_x_coord], snode[:node_y_coord]+1)
      #        tlnodes = SpinNode.where( "node_name LIKE \'%#{qstr}%\' AND node_x_pr_coord = ? AND node_y_coord = ?", snode[:node_x_coord], snode[:node_y_coord]+1)
      #        tlnodes |= tnodes
      tlnodes.each {|tln|
        if SpinAccessControl.is_accessible_node(sid, tln[:spin_node_hashkey]) and SpinAccessControl.is_parent_readable(sid, tln[:spin_node_hashkey])
          if tln[:node_type] == NODE_FILE
            nodes |= [ tln ]
          end
        end
      }
      #        sql_params = SystemTools::DbTools.build_sql_params 'spin_nodes', conditions
      #        conn = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      #        res = conn.exec_params sql_params[:sql], sql_params[:params]
      #      }
    else # => files in folder@folder_hash_key only
      #      file_list = SpinLocationManager.list_nodes(sid, conditions[:folder_hash_key], NODE_DIRECTORY)
      # returned files are accesible
      tfnodes = Array.new

      snode = SpinNode.find_by_spin_node_hashkey conditions[:folder_hash_key]
      q_conditions = my_query + query_for_search_nodes + ' AND node_x_pr_coord = ' + snode[:node_x_coord].to_s + ' AND node_y_coord = ' + (snode[:node_y_coord]+1).to_s + ' AND node_type = ' + NODE_FILE.to_s + ' AND latest = true AND is_void = false AND is_pending = false AND in_trash_flag = false'
      printf ">>> q_conditions {%s}\n",q_conditions
      tfnodes = SpinNode.where("#{q_conditions}")

      tfnodes.each {|tfn|
        if SpinAccessControl.is_accessible_node(sid, tfn[:spin_node_hashkey]) and SpinAccessControl.is_parent_readable(sid, tfn[:spin_node_hashkey])
          if tfn[:node_type] == NODE_FILE
            nodes |= [ tfn ]
          end
        end
      }
      #      file_list.each {|fl|
      #        if SpinAccessControl.is_accessible_node(sid, fl[:spin_node_hashkey]) and SpinAccessControl.is_parent_readable(sid, fl[:spin_node_hashkey]) and fl[:node_name] == conditions[:target_file_name]
      #          if fl[:node_type] == NODE_FILE
      #            tfnodes.append fl
      #          end
      #        end
      #      }
      #      nodes |= tfnodes
      #      file_list -= tfnodes
      #      file_list.each {|fll|
      #        if SpinAccessControl.is_accessible_node(sid, fll[:spin_node_hashkey]) and SpinAccessControl.is_parent_readable(sid, fll[:spin_node_hashkey]) and fll[:node_name].include?(conditions[:target_file_name])
      #          if fll[:node_type] == NODE_FILE
      #            nodes |= [ fll ]
      #          end
      #        end
      #      }
    end
    # advanced attribute search
    #
     
    # fill file list "S"
    
    return nodes
  end # => end of search_files
    
end
