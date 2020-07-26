# coding: utf-8
require 'const/stat_const'
require 'const/spin_types'
require 'tasks/request_broker'
require 'tasks/session_management'
require 'utilities/database_utilities'
require 'pg'
require 'pp'

class FilerDisplayController < ApplicationController
  # filer display controller
  include Stat
  include Types

  def proc_display_view
    #####################################################################################################
    # push params to spin_session table
    #####################################################################################################
    # request.headers.each { |hdr|
    # logger.debug "REQUEST HEADERS = #{hdr}"
    # # pp hdr
    # }
    # pp request
    rethash = Hash.new
    cks = request.headers["HTTP_COOKIE"]
    #    ck = cks.split(/=/)
    #    current_session = ck[1]
    # rp = request.headers["REQUEST_PATH"]
    # logger.debug "REQUEST_PATH = #{rp}"
    rp = request.headers["REQUEST_URI"]
    # pp "REQUEST_URI = "
    # pp rp
    rp0 = rp.split(/\?/)
    rpt = rp0[0].split(/\//)
    req = rpt[-1]
    # get spin session id
    # pp req
    ss_ses_id = ''
    if request['ses_id'].present?
      ss_ses_id = request['ses_id']
    else
      stmp = request.headers["HTTP_REFERER"]
      if stmp.present? # => there is REFERFER
        stmp2 = stmp.split(/=/)
        ss_ses_id = stmp2[-1] # => the last element is the spin session id
      else
        ss_ses_id = nil
      end
    end
    ####################################################################################################
    # Authenticate session
    #################### #################################################################################
    # cs = SessionManager.auth_rails_session current_session
    # unless cs
    # render :json => { success: false, status: false, errors: '無効なセッションです'}
    # return      
    # end
    #####################################################################################################
    # build display data for this session
    #####################################################################################################
    rethash = display_data_manager(ss_ses_id, req, params)
    begin
      if rethash[:success] == true
        #      if req == 'active_operator.sfl'
        #        render :json => rethash[:operator], :encoding => 'UTF-8'
        #      else
        display_data = rethash[:display_data]
        puts display_data
        render json: display_data, encoding: 'UTF-8' and return
        #      end
      else # => RequestBroker returned false status
        if rethash[:errors] != nil
          render json: {success: false, status: rethash[:status], errors: rethash[:errors]} and return
        else
          render json: {success: false, status: ERROR_ACCESS_DENIED, errors: 'アクセスが拒否されました!'} and return
        end
      end # => end of if rethash[:success] == true
    rescue JSON::ParserError
      error_string = "Invalid JSON : parse error = " + display_data
      render json: {success: false, status: rethash[:status], errors: error_string} and return
    rescue
      error_string = "Unknown error!"
      render json: {success: false, status: rethash[:status], errors: error_string} and return
    end
    render json: rethash[:display_data], encoding: 'UTF-8'
  end

  # => end of filer_display

  def display_data_manager ssid, req, rparams
    # pp req
    # pp rparams
    # parse request and build display data
    rethash = Hash.new
    client_data_id = "N/A"
    if rparams[:id].present?
      client_data_id = rparams[:id]
    end
    rethash = {success: true, status: true, id: client_data_id, display_data: {}}
    case req
    when 'domains.sfl'
      rethash = display_data_factory ssid, 'folder_a_domain', 'json'
      rethash = display_data_factory ssid, 'folder_b_domain', 'json'
    when 'domainsA.sfl'
      rethash = display_data_factory ssid, 'folder_a_domain', 'json'
    when 'domainsB.sfl'
      rethash = display_data_factory ssid, 'folder_b_domain', 'json'
    when 'foldersA.sfl'
      rethash = display_data_factory ssid, 'folder_a', 'json'
      #    when 'foldersB.sfl'
      #      rethash = display_data_factory ssid, 'folder_b', 'json'
      #    when 'foldersAT.sfl'
      #      rethash = display_data_factory ssid, 'folder_at', 'json'
      #    when 'foldersBT.sfl'
      #      rethash = display_data_factory ssid, 'folder_bt', 'json'
      #    when 'foldersATFi.sfl'
      #      rethash = display_data_factory ssid, 'folder_atfi', 'json'
      #    when 'foldersBTFi.sfl'
      #      rethash = display_data_factory ssid, 'folder_btfi', 'json'
    when 'file_listA.sfl'
      rethash = display_data_factory ssid, 'file_listA', 'json'
      #    when 'file_listB.sfl'
      #      rethash = display_data_factory ssid, 'file_listB', 'json'
    when 'file_listS.sfl'
      rethash = display_data_factory ssid, 'file_listS', 'json'
    when 'recycler.sfl'
      rethash = display_data_factory ssid, 'recycler', 'json'
    when 'user_list.sfl'
      rethash = display_data_factory ssid, 'user_list', 'json'
    when 'select_list.sfl'
      rethash = display_data_factory ssid, 'select_list', 'json'
    when 'group_list_tree.sfl'
      rethash = display_data_factory ssid, 'group_list_tree', 'json'
    when 'group_list_all.sfl'
      rethash = display_data_factory ssid, 'group_list_all', 'json'
    when 'group_list_created.sfl'
      rethash = display_data_factory ssid, 'group_list_created', 'json'
    when 'member_list_mygroup.sfl'
      #      GroupDatum.reset_folder_group_access_list(ssid, GROUP_LIST_DATA_USER_PRIMARY_GROUP)
      rethash = display_data_factory ssid, 'member_list_mygroup', 'json'
    when 'group_list_file.sfl'
      rethash = display_data_factory ssid, 'group_list_file', 'json'
    when 'group_list_folder.sfl'
      rethash = display_data_factory ssid, 'group_list_folder', 'json'
    when 'active_operator.sfl'
      rethash = display_data_factory ssid, 'active_operator', 'json'
    when 'search_condition.sfl'
      rethash = display_data_factory ssid, 'search_condition', 'json'
    when 'search_option.sfl'
      rethash = display_data_factory ssid, 'search_option', 'json'

    when 'clipboards.sfl'
      rethash = display_data_factory ssid, 'clipboards', 'json'

    when 'ArchivedData.sfl'
      rethash = display_data_factory ssid, 'ArchivedData', 'json'

    when 'SyncedData.sfl'
      rethash = display_data_factory ssid, 'SyncedData', 'json'

    when 'dlfolders.sfl'
      rethash = display_data_factory ssid, 'dlfolders', 'json'

    when 'dlfiles.sfl'
      rethash = display_data_factory ssid, 'dlfolders', 'json'

    else
      rethash = display_data_factory ssid, 'object_listX', 'json', req # => dummy!
    end
    return rethash
    # rethash = { success: true, status: true, data: { domain: [ "mydomain", "domainA"] }}
  end

  # => end of display_data_manager

  def display_data_factory ssid, data_type, data_format, data_file = "dummy_data"
    # like request broker
    rethash_f = Hash.new
    l_offset = 0
    l_limit = 0
    rethash = Hash.new
    # rethash_f = {success: false, status: INITIAL_STATE, display_data: []}
    case data_type
    when 'domains'
      # # fill domains with spin session_id == ssid
      rethash = DomainDatum.fill_domains ssid, 'domains'
      if rethash[:success] == true
        if rethash[:result] >= 0
          disp_domain_obj = DomainDatum.get_domain_display_data ssid, 'folder_a' # array of domain object
          # pp disp_domain_obj
          if disp_domain_obj.present?
            disp_domain_wrapper = {domains: disp_domain_obj}
            rethash[:display_data] = disp_domain_wrapper
          end
        else
          rethash[:status] = ERROR_NO_DOMAINS
          rethash[:errors] = "ドメイン情報がありません"
          disp_domain_wrapper = {domains: []}
          rethash[:display_data] = disp_domain_wrapper
          rethash = {success: false, status: ERROR_NO_DOMAINS, errors: "ドメイン情報がありません"}
        end
      else
        rethash[:success] = false
        rethash[:status] = ERROR_NO_DOMAINS
        rethash[:errors] = "ドメイン情報を取得出来ませんでした"
        disp_domain_wrapper = {domains: []}
        rethash[:display_data] = disp_domain_wrapper
        rethash = {success: false, status: ERROR_GET_DOMAINS_FAILED, errors: "ドメイン情報を取得出来ませんでした"}
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'folder_a_domain', 'folder_b_domain'
      # # fill domains with spin session_id == ssid
      rethash = Hash.new
      data_type.gsub!(/_domain/, '')
      ds = Array.new
      begin
        ds = DomainDatum.where(["session_id = ? AND cont_location = ?", ssid, data_type])
        if ds.present?
          ds.each {|d|
            d.destroy
          }
        end
      rescue ActiveRecord::RecordNotFound
        # => do nothing
      end

      rethash = DomainDatum.fill_domains ssid, data_type
      if rethash.present? && rethash[:success] == true
        if rethash[:result] >= 0
          disp_domain_obj_ar = DomainDatum.get_domain_display_data ssid, data_type
          disp_domain_obj = Array.new
          disp_domain_obj_ar.each {|arobj|
            hobj = Hash.new
            arobj.attributes.each {|key, value|
              hobj[key] = value
            }
            disp_domain_obj.push(hobj)
          }
          # pp disp_domain_obj
          disp_domain_wrapper = {domains: disp_domain_obj}
          rethash[:display_data] = disp_domain_wrapper
          puts rethash
        else
          rethash[:success] = false
          rethash[:status] = ERROR_NO_DOMAINS
          rethash[:errors] = "ドメイン情報がありません"
          disp_domain_wrapper = {domains: []}
          rethash[:display_data] = disp_domain_wrapper
        end
      else
        rethash[:status] = ERROR_NO_DOMAINS
        rethash[:errors] = "ドメイン情報を取得出来ませんでした"
        disp_domain_wrapper = {domains: []}
        rethash[:display_data] = disp_domain_wrapper
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'folder_a' # => ,'folder_b','folder_at','folder_bt','folder_atfi','folder_btfi'
      # # fill folders with spin session_id == ssid
      #sleep(1) # フォルダをゴミ箱に移動するとフォルダリストから消えるがタイミングによっては復活する問題の確認
      rethash = Hash.new
      rethash = {success: true, status: true, result: 1}
      disp_folder_obj = Array.new
      rethash = FolderDatum.fill_folders ssid, data_type
      if rethash[:success] == true
        if rethash[:result] >= 0
          if params[:Rebuilding_flag] == "1"
            FolderDatum.fill_folders(ssid, "folder_a")
          end
          ret_disp_folder_obj_ar = FolderDatum.get_folder_display_data ssid, data_type
          # ret_disp_file_list_obj_r = FileDatum.get_file_list_display_data ssid, my_data_type, l_offset, l_limit
          if ret_disp_folder_obj_ar.present?
            ret_disp_folder_obj = Array.new
            ret_disp_folder_obj_ar.each {|arobj|
              hobj = Hash.new
              arobj.each {|key, value|
                hobj[key] = value
              }
              ret_disp_folder_obj.push(hobj)
            }
            pp ret_disp_folder_obj.length
            if ret_disp_folder_obj_ar.count > 0
              # disp_folder_wrapper = {foldersA: ret_disp_folder_obj}
              rethash[:display_data] = ret_disp_folder_obj
              rethash[:success] = true
            else
              rethash[:status] = INFO_NO_FOLDERS
              rethash[:info] = "フォルダがありませんでした"
              # disp_folder_wrapper = {foldersA: ret_disp_folder_obj}
              rethash[:display_data] = ret_disp_folder_obj
            end
          else
            rethash[:status] = INFO_NO_FOLDERS
            rethash[:info] = "フォルダがありません"
            # disp_folder_wrapper = {foldersA: ret_disp_folder_obj}
            rethash[:display_data] = ret_disp_folder_obj
          end
        else
          rethash[:status] = ERROR_GET_FOLDERS_FAILED
          rethash[:errors] = "フォルダ情報を取得出来ませんでした"
          rethash[:display_data] = []
        end
      else
        rethash[:status] = ERROR_GET_FOLDERS_FAILED
        rethash[:errors] = "フォルダ情報を取得出来ませんでした"
        # disp_folder_wrapper = {foldersA: []}
        rethash[:display_data] = ret_disp_folder_obj
      end
      rethash_f = rethash
    when 'file_listA' # => ,'file_listB'
      my_data_type = (data_type == 'file_listA' ? 'folder_a' : 'folder_b')
      rethash = {success: true, result: 1}
      #      l_page = params[:page]
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      #      rethash = FileDatum.fill_file_list ssid, my_data_type
      rethash = FileDatum.fill_file_list ssid, my_data_type, l_offset, l_limit
      if rethash[:success] == true
        if rethash[:result] >= 0
          ret_disp_file_list_obj_r = FileDatum.get_file_list_display_data ssid, my_data_type, l_offset, l_limit
          if ret_disp_file_list_obj_r.present?
            ret_disp_file_list_obj_ar = ret_disp_file_list_obj_r[:display_object]
            ret_disp_file_list_obj = Array.new
            ret_disp_file_list_obj_ar.each {|arobj|
              hobj = Hash.new
              arobj.attributes.each {|key, value|
                hobj[key] = value
              }
              ret_disp_file_list_obj.push(hobj)
            }
            pp ret_disp_file_list_obj.length
            if ret_disp_file_list_obj_r[:success] == true
              disp_file_list_wrapper = {success: true, total: ret_disp_file_list_obj_r[:total], start: ret_disp_file_list_obj_r[:start], limit: ret_disp_file_list_obj_r[:limit], files: ret_disp_file_list_obj}
              rethash[:display_data] = disp_file_list_wrapper
              rethash[:success] = true
              rethash[:status] = true
            else
              rethash[:status] = ERROR_GET_FILE_LIST_FAILED
              rethash[:errors] = "ファイル情報を取得出来ませんでした"
              disp_file_list_wrapper = {success: false, total: 0, start: l_offset, limit: l_limit, files: []}
              rethash[:display_data] = disp_file_list_wrapper
            end
          else
            rethash[:status] = ERROR_GET_FILE_LIST_FAILED
            rethash[:errors] = "ファイル情報を取得出来ませんでした"
            disp_file_list_wrapper = {success: false, total: 0, start: l_offset, limit: l_limit, files: []}
            rethash[:display_data] = disp_file_list_wrapper
          end
        elsif rethash[:result] == 0
          disp_file_list_wrapper = {succes: true, total: 0, start: l_offset, limit: l_limit, files: []}
          rethash[:display_data] = disp_file_list_wrapper
          rethash[:status] = INFO_NO_FILES
          rethash[:info] = "ファイル／フォルダがありません"
        else
          rethash[:status] = INFO_NO_FILES
          rethash[:info] = "ファイル／フォルダがありません"
          disp_file_list_wrapper = {success: true, total: 0, start: l_offset, limit: l_limit, files: []}
          rethash[:display_data] = disp_file_list_wrapper
        end
      else
        rethash[:status] = ERROR_GET_FILE_LIST_FAILED
        rethash[:errors] = "ファイル情報を取得出来ませんでした"
        disp_file_list_wrapper = {success: false, total: 0, start: ret_disp_file_list_obj[:start], limit: ret_disp_file_list_obj[:limit], files: []}
        rethash[:display_data] = disp_file_list_wrapper
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'file_listS'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      ret_disp_search_file_list_obj_r = FileDatum.get_search_file_list_display_data ssid, 'search_result', l_offset, l_limit
      ret_disp_search_file_list_obj_ar = ret_disp_search_file_list_obj_r[:display_object]
      ret_disp_search_file_list_obj = Array.new
      ret_disp_search_file_list_obj_ar.each {|arobj|
        hobj = Hash.new
        arobj.attributes.each {|key, value|
          hobj[key] = value
        }
        ret_disp_search_file_list_obj.push(hobj)
      }
      pp disp_search_file_list_obj.length
      if ret_disp_search_file_list_obj_r.present? && ret_disp_search_file_list_obj_r[:success] == false
        rethash[:status] = ERROR_GET_FILE_LIST_FAILED
        rethash[:errors] = "ファイル情報を取得出来ませんでした"
        disp_search_file_list_wrapper = {success: false, total: 0, start: l_offset, limit: l_limit, files: []}
        rethash[:display_data] = disp_search_file_list_wrapper
      else
        disp_search_file_list_wrapper = {success: true, total: ret_disp_search_file_list_obj_r[:total], start: ret_disp_search_file_list_obj_r[:start], limit: ret_disp_search_file_list_obj_r[:limit], files: ret_disp_search_file_list_obj}
        rethash[:display_data] = disp_search_file_list_wrapper
        rethash[:success] = true
        rethash[:status] = INFO_SEARCH_FILES_SUCCESS
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'group_list_tree'
      group_name = String.new
      rethash = Hash.new
      begin
        group_name = params[:group_name];
      rescue
        rethash[:success] = true
        rethash[:display_data] = Array.new
        return rethash
      end
      if group_name.present?
        if group_name == '__clear';
          rethash[:success] = true
          rethash[:display_data] = []
          return rethash
        end
        disp_group_list_tree = GroupDatum.select_group_member_display_tree group_name
        if disp_group_list_tree.present?
          rethash[:success] = disp_group_list_tree[:success]
          rethash[:display_data] = disp_group_list_tree
        else
          rethash[:success] = true
          rethash[:display_data] = []
        end
      else
        rethash[:success] = true
        rethash[:display_data] = Array.new
      end
      rethash_f = rethash
      # rethash_f.merge!(rethash)
    when 'group_list_all'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      group_name = params[:group_name];
      disp_group_list_obj = GroupDatum.select_group_member_display_data group_name, l_offset, l_limit
      if disp_group_list_obj.present?
        rethash[:success] = disp_group_list_obj[:success]
        rethash[:status] = disp_group_list_obj[:status]
        rethash[:display_data] = disp_group_list_obj
      else
        rethash[:success] = true
        rethash[:status] = INFO_NO_GROUPS
        rethash[:display_data] = []
      end
      rethash_f = rethash
      # rethash_f.merge!(rethash)
    when 'user_list'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      disp_user_list_obj = SpinUser.get_user_list_display_data ssid, l_offset, l_limit
      if disp_user_list_obj.present?
        rethash[:success] = disp_user_list_obj[:success]
        rethash[:status] = disp_user_list_obj[:status]
        rethash[:display_data] = disp_user_list_obj
      else
        rethash[:success] = disp_user_list_obj[:success]
        rethash[:status] = INFO_NO_USERS
        rethash[:display_data] = []
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'select_list'
      l_offset = params[:start]
      l_limit = params[:limit]
      rethash = Hash.new
      form_data_hash = {}
      form_data_hash[:user_name] = params[:user_name]
      form_data_hash[:real_uname] = params[:real_uname]
      form_data_hash[:user_post] = params[:user_post]
      form_data_hash[:user_mail] = params[:user_mail]
      form_data_hash[:company_name] = params[:company_name]
      form_data_hash[:employee_number] = params[:employee_number]
      form_data_hash[:p_group_name] = params[:p_group_name]
      form_data_hash[:p_group_description] = params[:p_group_description]
      disp_user_list_obj = SpinUser.select_user_list_display_data ssid, l_offset, l_limit, form_data_hash

      rethash[:success] = disp_user_list_obj[:success]
      rethash[:status] = disp_user_list_obj[:status]
      rethash[:display_data] = disp_user_list_obj[:users]
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'group_list_folder'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      add_flag = params[:add_flag].to_i
      rethash = Hash.new
      target_hashkey = ''
      if (params[:target] == 'folderPanelA')
        fd = FolderDatum.find_by(hash_key: params[:hash_key])
        if fd.present?
          target_hashkey = fd[:spin_node_hashkey]
        end
      else
        fd = FileDatum.find_by(hash_key: params[:hash_key])
        if fd.present?
          target_hashkey = fd[:spin_node_hashkey]
        end
      end
      ret_disp_group_list_obj_r = GroupDatum.get_folder_group_access_list ssid, GROUP_LIST_FOLDER, l_offset, l_limit, add_flag, target_hashkey
      ret_disp_group_list_obj_ar = ret_disp_group_list_obj_r[:groups]
      ret_disp_group_list_obj = Array.new
      ret_disp_group_list_obj_ar.each {|arobj|
        hobj = Hash.new
        arobj.attributes.each {|key, value|
          hobj[key] = value
        }
        ret_disp_group_list_obj.push(hobj)
      }
      if ret_disp_group_list_obj_r.present? && ret_disp_group_list_obj_r[:success]
        ret_disp_group_list_obj.uniq!
        ret_disp_group_list_obj.sort! {|a, b| a.group_name <=> b.group_name}
      end
      rethash[:success] = ret_disp_group_list_obj_r[:success]
      rethash[:status] = ret_disp_group_list_obj_r[:status]
      rethash[:display_data] = ret_disp_group_list_obj
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'group_list_file'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      disp_group_list_obj = GroupDatum.get_file_group_access_list ssid, GROUP_LIST_FILE, l_offset, l_limit
      if disp_group_list_obj.present? && disp_group_list_obj[:success]
        disp_group_list_obj[:groups].uniq!
        disp_group_list_obj[:groups].sort! {|a, b| a.group_name <=> b.group_name}
      end
      rethash[:success] = disp_group_list_obj[:success]
      rethash[:status] = disp_group_list_obj[:status]
      rethash[:display_data] = disp_group_list_obj
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'group_list_created'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      disp_group_list_obj = GroupDatum.get_group_list_display_data ssid, GROUP_LIST_CREATED, l_offset, l_limit
      disp_groups = []
      if disp_group_list_obj.present? && disp_group_list_obj[:success]
        disp_group_list_obj[:groups].each {|g|
          rec = {}
          rec[:hash_key] = 'NOT_SPECIFIED'
          rec[:target_hash_key] = 'NOT_SPECIFIED'
          rec[:group_name] = g[:spin_group_name]
          rec[:group_description] = g[:group_descr]
          rec[:group_id] = g[:spin_gid]
          disp_groups.push rec
        }
      end
      disp_group_list_obj[:groups] = disp_groups
      rethash[:success] = disp_group_list_obj[:success]
      rethash[:status] = disp_group_list_obj[:status]
      rethash[:display_data] = disp_group_list_obj
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'member_list_mygroup'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      disp_group_member_list_obj = GroupDatum.get_group_list_display_data ssid, GROUP_MEMBER_LIST_SELECTED, l_offset, l_limit
      if disp_group_member_list_obj.present? && disp_group_member_list_obj[:success]
        #        disp_group_member_list_obj[:groups].uniq!
        disp_group_members = []
        total_groups = 0
        disp_group_member_list_obj[:members].each {|g|
          #          "group_name": "a クライアント",
          #          "group_description": "A社",
          #          "member_name": "伊藤博文",
          #          "member_description": "広告宣伝部",
          #          "member_id": "d1-0001",
          #          "member_remark": "なし"
          rec = {}
          rec[:group_name] = SpinGroup.get_group_name(g[0][:spin_gid])
          rec[:group_description] = SpinGroup.get_group_description(rec[:group_name])
          rec[:member_name] = g[0][:spin_uname]
          rec[:member_id] = g[0][:spin_uid]
          rec[:member_remark] = 'NO REMARKS'
          disp_group_members.push rec
          total_groups += 1
        }
        disp_group_member_list_obj[:members] = disp_group_members
        rethash[:total] = total_groups
        rethash[:success] = disp_group_member_list_obj[:success]
        rethash[:status] = disp_group_member_list_obj[:status]
        rethash[:display_data] = disp_group_member_list_obj
      elsif disp_group_member_list_obj.present? # disp_group_member_list_obj[:success] == false
        disp_group_members = []
        total_groups = 0
        disp_group_member_list_obj[:members] = disp_group_members
        rethash[:total] = total_groups
        rethash[:success] = false
        rethash[:status] = INFO_NO_MY_GROUPS
        rethash[:display_data] = disp_group_member_list_obj
      else
        disp_group_members = []
        total_groups = 0
        rethash[:total] = total_groups
        rethash[:success] = false
        rethash[:status] = INFO_NO_MY_GROUPS
        rethash[:display_data] = []
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'active_operator'
      rethash = Hash.new
      active_operator = SpinUserAttribute.get_active_operator ssid
      active_operators = Array.new
      if active_operator.present?
        active_operators.push active_operator
      end
      rethash[:success] = true
      rethash[:status] = "200 OK"
      rethash[:display_data] = active_operators
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'search_condition'
      rethash = Hash.new
      active_operator = SpinUserAttribute.get_active_operator ssid
      active_operators = Array.new
      if active_operator.present?
        active_operators.push active_operator
      end
      rethash[:success] = true
      rethash[:status] = "200 OK"
      rethash[:display_data] = active_operators
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'search_option'
      # node_request = request;
      # node_hash_key = request.headers["HTTP_HASH_KEY"];
      # 以下は決まっている検索項目なので初期値として追加する。
      rethash = Hash.new
      node_search_option = []
      node_search_option = [{option_name: "説明", field_name: "node_description", value: ""}]
      node_search_option.push({option_name: "メモ1", field_name: "memo1", value: ""})
      node_search_option.push({option_name: "メモ2", field_name: "memo2", value: ""})
      node_search_option.push({option_name: "メモ3", field_name: "memo3", value: ""})
      node_search_option.push({option_name: "メモ4", field_name: "memo4", value: ""})
      node_search_option.push({option_name: "メモ5", field_name: "memo5", value: ""})
      node_search_option.push({option_name: "内容詳細", field_name: "details", value: ""})
      if params[:spin_node_hashkey].present? # search_optionのJSONストレージをハッシュ値ありでロードした時
        search_option_node_hashkey = params[:spin_node_hashkey];
        #active_operator = SpinUserAttribute.get_active_operator ssid
        #SpinNode.transaction do
        res = SpinNode.readonly.select("node_attributes,node_type").find_by_spin_node_hashkey(search_option_node_hashkey)
        #res = SpinNode.readonly.select("node_attributes,node_description,details").find(["spin_node_hashkey = ?" , search_option_node_hashkey])
        #end
        if res.present?
          node_attribute_json = res[:node_attributes]
          node_type = res[:node_type]
          #setumei = res[:node_description]
          #node_search_option = [{:option_name => "説明", :field_name => "node_description", :value => ""}]
          #shousai = res[:detail]
          #node_search_option.push({:option_name => "内容詳細", :field_name => "details", :value => ""})
          if (node_type === 2)
            node_attribute_json = res[:node_attributes]
            begin
              node_attribute = JSON.parse(node_attribute_json)
              node_attribute.each do |key, value|
                if (key === "type")
                  next
                end
                if (key === "client")
                  next
                end
                if (key === "copyright")
                  next
                end
                if (key === "music")
                  next
                end
                if (key === "title")
                  next
                end
                if (key === "subtitle")
                  next
                end
                if (key === "keyword")
                  next
                end
                if (key === "duration")
                  # メモ１で予約済みなので使用不可
                  next
                end
                if (key === "producer")
                  # メモ２で予約済みなので使用不可
                  next
                end
                if (key === "produced_date")
                  # メモ３で予約済みなので使用不可
                  next
                end
                if (key === "location")
                  # メモ４で予約済みなので使用不可
                  next
                end
                if (key === "cast")
                  # メモ５で予約済みなので使用不可
                  next
                end
              end
            rescue

            end
          else
            # ノードタイプがファイル以外の場合はここに追加
          end
        else
          # spin_nodesへのアクセスが失敗した場合はここに落ちる。
        end
      else
        # search_optionのJSONストレージをハッシュ値なしでロードした時
      end
      rethash[:success] = true
      rethash[:status] = "200 OK"
      #      rethash[:display_data] = active_operator
      #rethash[:display_data] = { :operator => [ active_operator ] }
      rethash[:display_data] = {option: node_search_option}
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'recycler'
      l_page = params[:page]
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      disp_recycler_wrapper = Hash.new
      disp_recycler_obj = RecyclerDatum.get_recycler_display_data ssid, l_offset, l_limit
      if disp_recycler_obj.present? && disp_recycler_obj[:success] == true
        rethash[:success] = true
        rethash[:status] = INFO_RECYCLER_LIST_SUCCESS
        rethash[:result] = disp_recycler_obj.count
        rethash[:display_data] = disp_recycler_obj
      else
        rethash[:success] = false
        rethash[:status] = ERROR_RECYCLER_LIST
        rethash[:errors] = "ゴミ箱情報を取得出来ませんでした"
        rethash[:display_data] = []
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash

    when 'clipboards'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      disp_clipboard_obj = ClipBoards.get_clipboards_display_data ssid, l_offset, l_limit
      if disp_clipboard_obj.present? && disp_clipboard_obj[:success] == true
        rethash[:success] = true
        rethash[:status] = INFO_RECYCLER_LIST_SUCCESS
        rethash[:result] = disp_clipboard_obj.count
        rethash[:display_data] = disp_clipboard_obj
      else
        rethash[:success] = false
        rethash[:status] = ERROR_RECYCLER_LIST
        rethash[:errors] = "クリップボード情報を取得出来ませんでした"
        rethash[:display_data] = []
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash

    when 'ArchivedData'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      rethash = Hash.new
      # total = SpinNode.get_archived_folder 0, 'total'
      archived_folder_list = SpinNode.get_archived_folder l_offset, l_limit
      display_data = Hash.new;
      if archived_folder_list.present?
        display_data[:files] = archived_folder_list;
        display_data[:limit] = l_limit;
        display_data[:start] = l_offset;
        display_data[:success] = true;
        display_data[:total] = archived_folder_list.count
      else
        display_data[:files] = [];
        display_data[:limit] = l_limit;
        display_data[:start] = l_offset;
        display_data[:success] = true;
        display_data[:total] = 0;
      end
      rethash[:success] = true
      rethash[:status] = "200 OK"
      rethash[:display_data] = display_data;
      # rethash_f.merge!(rethash)
      rethash_f = rethash

    when 'SyncedData'
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      # total = SpinNode.get_synced_folder 0, 'total'
      synced_folder_list = SpinNode.get_synced_folder l_offset, l_limit
      display_data = Hash.new;
      if synced_folder_list.present?
        display_data[:files] = synced_folder_list;
        display_data[:limit] = l_limit;
        display_data[:start] = l_offset;
        display_data[:success] = true;
        display_data[:total] = synced_folder_list.count;
      else
        display_data[:files] = [];
        display_data[:limit] = l_limit;
        display_data[:start] = l_offset;
        display_data[:success] = true;
        display_data[:total] = 0;
      end
      rethash[:success] = true
      rethash[:status] = "200 OK"
      rethash[:display_data] = display_data;
      # rethash_f.merge!(rethash)
      rethash_f = rethash

    when 'dlfolders'
      rethash = {success: true, status: true, result: 1}
      disp_folder_obj = []
      rethash = FolderDatum.fill_folders ssid, data_type
      if rethash[:success] == true
        if rethash[:result] >= 0
          disp_folder_obj = FolderDatum.get_folder_display_data ssid, 'folder_a'
          pp disp_folder_obj
          if disp_folder_obj.present?
            disp_folder_wrapper = {folders: disp_folder_obj}
            rethash[:display_data] = disp_folder_wrapper
          else
            rethash[:status] = INFO_NO_FOLDERS
            rethash[:info] = "フォルダがありません"
            rethash[:display_data] = []
          end
        else
          rethash[:status] = ERROR_GET_FOLDERS_FAILED
          rethash[:errors] = "フォルダ情報を取得出来ませんでした"
          rethash[:display_data] = []
        end
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    when 'dlfiles.sfl'
      my_data_type = (data_type == 'file_listA' ? 'folder_a' : 'folder_b')
      rethash = {success: true, result: 1}
      #      l_page = params[:page]
      l_offset = params[:start].to_i
      l_limit = params[:limit].to_i
      #      rethash = FileDatum.fill_file_list ssid, my_data_type
      rethash = FileDatum.fill_file_list ssid, my_data_type, l_offset, l_limit
      if rethash[:success] == true
        if rethash[:result] >= 0
          ret_disp_file_list_obj = FileDatum.get_file_list_display_data ssid, my_data_type, l_offset, l_limit
          pp ret_disp_file_list_obj.length
          if ret_disp_file_list_obj.present? && ret_disp_file_list_obj[:success] == false
            rethash[:status] = ERROR_GET_FILE_LIST_FAILED
            rethash[:errors] = "ファイル情報を取得出来ませんでした"
            disp_file_list_wrapper = {success: false, total: 0, start: l_offset, limit: l_limit, files: []}
            rethash[:display_data] = disp_file_list_wrapper
          elsif ret_disp_file_list_obj.present?
            disp_file_list_wrapper = {success: true, total: ret_disp_file_list_obj[:total], start: ret_disp_file_list_obj[:start], limit: ret_disp_file_list_obj[:limit], files: ret_disp_file_list_obj[:display_object]}
            rethash[:display_data] = disp_file_list_wrapper
            rethash[:success] = true
            rethash[:status] = true
          else
            rethash[:status] = ERROR_GET_FILE_LIST_FAILED
            rethash[:errors] = "ファイル情報を取得出来ませんでした"
            disp_file_list_wrapper = {success: false, total: 0, start: l_offset, limit: l_limit, files: []}
            rethash[:display_data] = disp_file_list_wrapper
          end
        elsif rethash[:result] == 0
          disp_file_list_wrapper = {succes: true, total: 0, start: l_offset, limit: l_limit, files: []}
          rethash[:display_data] = disp_file_list_wrapper
          rethash[:success] = true
          rethash[:status] = INFO_NO_FILES
          rethash[:info] = "ファイル／フォルダがありません"
        else
          rethash[:status] = INFO_NO_FILES
          rethash[:info] = "ファイル／フォルダがありません"
          disp_file_list_wrapper = {success: true, total: 0, start: l_offset, limit: l_limit, files: []}
          rethash[:display_data] = disp_file_list_wrapper
        end
      else
        rethash[:status] = ERROR_GET_FILE_LIST_FAILED
        rethash[:errors] = "ファイル情報を取得出来ませんでした"
        disp_file_list_wrapper = {success: false, total: 0, start: ret_disp_file_list_obj[:start], limit: ret_disp_file_list_obj[:limit], files: []}
        rethash[:display_data] = disp_file_list_wrapper
      end

    else
      # load contents from JSON file for dummy output
      json_fname = File.dirname(__FILE__) + "/../../public/secret_files/_spin/" + data_file
      # pp json_fname
      sfl_contents = ""
      sfl_array = []
      if File.exist? json_fname
        File.open(json_fname) {|f| sfl_contents << f.read}
      end
      if sfl_contents.blank? # sfl_contents == "" or sfl_contents == nil #by IMAI 2015/1/20
        # pp sfl_obj
        sfl_obj = {}
        sfl_array.push sfl_obj
        rethash = {success: true, status: true, display_data: sfl_array, result: 0} # => dummy return hash always true
      else
        sfl_obj = JSON.parse sfl_contents
        # pp sfl_obj
        sfl_array.push sfl_obj
        rethash = {success: true, status: true, display_data: sfl_array, result: 1} # => dummy return hash always true
      end
      # rethash_f.merge!(rethash)
      rethash_f = rethash
    end # => end of 'case' statement
    return rethash_f
  end # => end of display_data_factory
end # => end of FilerDisplayController

