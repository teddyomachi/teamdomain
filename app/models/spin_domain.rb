# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'

class SpinDomain < ActiveRecord::Base
  include Vfs
  include Acl

  attr_accessor :created_at, :updated_at, :domain_atrtributes, :cont_location, :domain_descr, :spin_did, :spin_domain_disp_name, :spin_domain_name, :spin_domain_root, :spin_server, :domain_writeble_status, :domain_link, :img

  def self.get_domain_root_node node_key
    r = self.find_by(hash_key: node_key)
    unless r.blank?
      return r
    else
      return self.find_by(spin_domain_name: 'personal')
    end
  end

  # => end of get_domain_root_node

  def self.get_domain_root_node_by_name domain_name
    begin
      r = self.find_by(spin_domain_disp_name: domain_name)
      if r.blank?
        return self.find_by(spin_domain_name: 'personal')
      end
    rescue ActiveRecord::RecordNotFound
      return self.find_by(spin_domain_name: 'personal')
    end
    return r[:spin_domain_root]
  end

  # => end of get_domain_root_node

  def self.get_domain_root_node_key node_key
    r = self.find_by_hash_key node_key
    if r.present?
      return r[:domain_root_node_hashkey]
    else
      root_node = self.find_by(spin_domain_name: 'personal')
      if root_node.blank?
        return nil
      else
        return root_node[:domain_root_node_hashkey]
      end
    end
  end

  # => end of get_domain_root_node

  def self.get_domain_root_vpath node_key
    r = self.find_by_hash_key node_key
    if r.present?
      return r[:spin_domain_root]
    else
      root_node = self.find_by(spin_domain_name: 'personal')
      if root_node.blank? == nil
        return nil
      else
        return root_node[:spin_domain_root]
      end
    end
  end

  # => end of get_domain_root_node

  def self.get_system_default_domain
    default_domain = self.find_by(spin_domain_name: 'personal')
    if default_domain.blank?
      return nil
    else
      return default_domain[:hash_key]
    end
  end

  # => end of get_system_default_domain

  def self.search_accessible_domains sid, var_gids
    # search spin_access_control
    p_domains = Array.new
    #    acl_keys = acl_list.map {|a| a[:managed_node_hashkey]}
    # search spin_domains
    gids = Array.new
    uid = SessionManager.get_uid(sid)

    self.transaction do
      begin
        p_domains = self.readonly.where(["spin_uid = ? OR spin_world_access_right > ?", uid, Acl::ACL_NODE_NO_ACCESS])
      rescue ActiveRecord::RecordNotFound
        return p_domains
      end

      gids = var_gids.uniq

      gids.each {|gid|
        begin
          p_domains_g = self.readonly.where(["spin_gid = ? AND spin_gid_access_right > ?", gid, Acl::ACL_NODE_NO_ACCESS])
          if p_domains_g.blank?
            next
          end
          p_domains |= p_domains_g
        rescue ActiveRecord::RecordNotFound
          next
        end
      }

      # # check domain root nodes that are accessible
      # root_nodes = SpinNode.readonly.where(is_domain_root_node: true, is_pending: false, in_trash_flag: false, is_void: false)
      # accessible_root_nodes = Array.new
      # root_nodes.each {|rn|
      #   if SpinAccessControl.is_accessible_node(sid, rn[:spin_node_hashkey], NODE_DIRECTORY)
      #     accessible_root_nodes.push(rn[:spin_node_hashkey])
      #   end
      # }
      # spin_domains = self.all
      # accessible_root_nodes.each {|arn|
      #   spin_domains.each {|sd|
      #     if sd[:domain_root_node_hashkey] == arn
      #       p_domains |= [sd]
      #     end
      #   }
      # }

    end # => end of trasnaction

    # => find from acl
    domain_root_nodes = Array.new
    self.transaction do
      begin
        domain_root_nodes = SpinAccessControl.readonly.select('managed_node_hashkey').where(["spin_node_type = ?", Vfs::NODE_DOMAIN])
        if domain_root_nodes.blank?
          return p_domains
        end
      rescue ActiveRecord::RecordNotFound
        return p_domains
      end
    end # => end of transaction

    self.transaction do
      domain_root_node_acls = Array.new
      domain_root_nodes.each {|rn|
        begin
          domain_root_node_acls = SpinAccessControl.where(["managed_node_hashkey = ?", rn[:managed_node_hashkey]])
        rescue ActiveRecord::RecordNotFound
          return p_domains
        end
        domain_root_node_acls.each {|an|
          gids.each {|my_gid|
            if (an[:spin_gid] == my_gid and an[:spin_gid_access_right] > Acl::ACL_NODE_NO_ACCESS) or an[:spin_world_access_right] > Acl::ACL_NODE_NO_ACCESS
              #                  p_domains |= self.readonly.where(["hash_key = ?",an[:managed_node_hashkey]])
              begin
                p_domains_g = self.readonly.where(["domain_root_node_hashkey = ?", an[:managed_node_hashkey]])
                p_domains |= p_domains_g
              rescue ActiveRecord::RecordNotFound
                return p_domains
              end
            end
          } # => end of gids.each-block
        } # => end of domain_root_node_acls.each-block
      } # => end of domain_root_nodes.each-block
    end # => end of trasnaction

    p_domains.uniq

    return p_domains
  end

  # => end of search_accessible_domains my_uid, my_gids

  def self.is_accessible_domain sid, dom_hash_key
    # search spin_access_control
    p_domains = Array.new
    #    acl_keys = acl_list.map {|a| a[:managed_node_hashkey]}
    # search spin_domains
    gids = Array.new
    uid = SessionManager.get_uid(sid)

    self.transaction do
      begin
        p_domains = self.readonly.where(["hash_key = ? AND (spin_uid = ? OR spin_world_access_right > ?)", dom_hash_key, uid, Acl::ACL_NODE_NO_ACCESS])
      rescue ActiveRecord::RecordNotFound
        return p_domains
      end

      gids = var_gids.uniq

      gids.each {|gid|
        begin
          p_domains_g = self.readonly.where(["hash_key = ? AND spin_gid = ? AND spin_gid_access_right > ?", dom_hash_key, gid, Acl::ACL_NODE_NO_ACCESS])
          if p_domains_g.blank?
            next
          end
          p_domains |= p_domains_g
        rescue ActiveRecord::RecordNotFound
          next
        end
      }

    end # => end of trasnaction

    if p_domains.count > 0
      return true
    else
      return false
    end

  end

  # => end of search_accessible_domains my_uid, my_gids
  def self.set_domain_has_updated node_key

    retry_set_domain_has_updated = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_domain_has_updated_again) {
      SpinDomain.transaction do
        begin
          ds = self.where :domain_root_node_hashkey => node_key
          if ds.length > 0
            ds.each {|sdom|
              sdom.update(spin_updated_at: Time.now)
            }
          end
        rescue ActiveRecord::StaleObjectError
          if retry_set_domain_has_updated > 0
            retry_set_domain_has_updated -= 1
            throw :set_domain_has_updated_again
          end
        end
      end
    }
  end

  # => end of set_domain_has_updated

  def self.create_domain sid, node_key, target = 'folderPanelA'

    retry_count = ACTIVE_RECORD_RETRY_COUNT

    if target == 'folderPanelA' #20161111 T2L Comment
      folder_rec = FolderDatum.find_by(hash_key: node_key)
    else
      folder_rec = FileDatum.find_by(hash_key: node_key)
    end
    if folder_rec.blank?
      return -1
    end

    ids = SessionManager.get_uid_gid(sid, true)
    new_mem = {:member_id => ids[:uid], :group_name => SpinGroup.get_group_name(ids[:gid])}
    gids = []
    gids.append new_mem
    r = Random.new #20161111 T2L ADD
    hash_key = Security.hash_key_s node_key + r.rand.to_s #20161111 T2L ADD

    new_domain_rec = nil

    catch(:create_domain_again) {

      SpinDomain.transaction do

        begin
          max_did = SpinDomain.maximum("spin_did")
          new_domain_rec = SpinDomain.create {|new_domain|
            new_domain[:spin_did] = max_did + 1
            if target == 'folderPanelA' #20161111 T2L COmment
              new_domain[:spin_domain_name] = folder_rec[:folder_name]
              new_domain[:spin_domain_root] = folder_rec[:vpath]
              new_domain[:spin_domain_disp_name] = folder_rec[:folder_name]
            else
              new_domain[:spin_domain_name] = folder_rec[:file_name]
              new_domain[:spin_domain_root] = folder_rec[:virtual_path]
              new_domain[:spin_domain_disp_name] = folder_rec[:file_name]
            end
            new_domain[:domain_root_node_hashkey] = folder_rec[:spin_node_hashkey] #20161111 T2L Change @
            new_domain[:hash_key] = hash_key
            new_domain[:spin_server] = 'localhost'
            new_domain[:domain_writable_status] = true
            new_domain[:domain_link] = 'file_type_icon/Drawer.png'
            new_domain[:img] = 'file_type_icon/Drawer.png'
            new_domain[:spin_uid] = ids[:uid]
            new_domain[:spin_gid] = ids[:gid]
            new_domain[:spin_uid_access_right] = ACL_DEFAULT_UID_ACCESS_RIGHT
            new_domain[:spin_gid_access_right] = ACL_DEFAULT_GID_ACCESS_RIGHT
            new_domain[:spin_world_access_right] = ACL_DEFAULT_WORLD_ACCESS_RIGHT
            new_domain[:spin_updated_at] = Time.now
            new_domain[:domain_descr] = ''
            new_domain[:domain_attributes] = ''
            new_domain[:cont_location] = 'folder_a'
          }

          SpinAccessControl.add_groups_access_control(sid, folder_rec[:spin_node_hashkey], ACL_DEFAULT_GID_ACCESS_RIGHT, gids, NODE_DOMAIN) #20161111 T2L Comment
          domain_rec = DomainDatum.find_by(session_id: sid, hash_key: node_key)
          if domain_rec.present?
            delDomains = SpinDomain.where(["domain_root_node_hashkey = ? AND spin_uid = ? AND spin_gid = ?", domain_rec[:spin_domain_hash_key], ids[:uid], ids[:gid]]) #20161111 T2L Comment
            if delDomains
              delDomains.each {|da|
                da.destroy
              }
            end
            delAcs = SpinAccessControl.where(["managed_node_hashkey = ? AND spin_gid = ?", domain_rec[:spin_domain_hash_key], ids[:gid]]) #20161111 T2L Comment
            #          delAcs = SpinAccessControl.where(["root_node_hashkey = ? AND spin_gid = ?", node_key, ids[:gid]] ) #20161111 T2L Add
            if delAcs
              delAcs.each {|ac|
                ac.destroy
              }
            end
          end
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :create_domain_again
          else
            return false
          end # => end if retry_count > 0
        rescue ActiveRecord::RecordNotFound
          Rails.logger('create_domain : domain_data record or acl is not found')
        rescue
          Rails.logger('create_domain : exception')
        end # => end of block
      end # => end of transaction
    }

    return new_domain_rec
  end

  # => end of create_domain

  def self.modify_domain sid, params_hash

    if params_hash.blank? or params_hash[:hash_key].blank?
      return nil
    end
    ids = SessionManager.get_uid_gid(sid, true)
    new_mem = {:member_id => ids[:uid]}
    gids = [new_mem]

    domain_rec = self.find_by(hash_key: params_hash[:hash_key])
    if domain_rec.blank?
      return nil
    end

    v_spin_did = 0
    v_spin_domain_root = ''
    v_spin_domain_disp_name = ''
    v_domain_root_node_hashkey = ''
    v_domain_writable_status = false
    v_domain_link = ''
    v_img = ''
    v_spin_uid = 0
    v_spin_gid = 0
    v_spin_uid_access_right = ACL_DEFAULT_UID_ACCESS_RIGHT
    v_spin_gid_access_right = ACL_DEFAULT_GID_ACCESS_RIGHT
    v_spin_world_access_right = ACL_DEFAULT_WORLD_ACCESS_RIGHT

    retry_modify_domain = ACTIVE_RECORD_RETRY_COUNT
    catch(:modify_domain_again) {
      self.transaction do
        begin

          if params_hash[:spin_did].present?
            v_spin_did = params_hash[:spin_did]
          end
          if params_hash[:spin_domain_name].present?
            v_spin_domain_name = params_hash[:spin_domain_name]
          end
          if params_hash[:spin_domain_root].present?
            v_spin_domain_root = params_hash[:spin_domain_root]
          end
          if params_hash[:spin_domain_disp_name].present?
            v_spin_domain_disp_name = params_hash[:spin_domain_disp_name]
          end
          if params_hash[:domain_root_node_hashkey].present?
            v_domain_root_node_hashkey = params_hash[:domain_root_node_hashkey]
          end
          if params_hash[:domain_writable_status].present?
            v_domain_writable_status = params_hash[:domain_writable_status]
          end
          if params_hash[:domain_link].present?
            v_domain_link = params_hash[:domain_link]
          end
          if params_hash[:img].present?
            v_img = params_hash[:img]
          end
          if params_hash[:spin_uid].present?
            v_spin_uid = params_hash[:spin_uid]
          end
          if params_hash[:spin_gid].present?
            v_spin_gid = params_hash[:spin_gid]
          end
          if params_hash[:spin_uid_access_right].present?
            v_spin_uid_access_right = params_hash[:spin_uid_access_right]
          end
          if params_hash[:spin_gid_access_right].present?
            v_spin_gid_access_right = params_hash[:spin_gid_access_right]
          end
          if params_hash[:spin_world_access_right].present?
            v_spin_world_access_right = params_hash[:spin_world_access_right]
          end
          v_spin_updated_at = Time.now

          domain_rec.update(
              spin_did: v_spin_did,
              spin_domain_name: v_spin_domain_name,
              spin_domain_root: v_spin_domain_root,
              spin_domain_disp_name: v_spin_domain_disp_name,
              domain_root_node_hashkey: v_domain_root_node_hashkey,
              domain_writable_status: v_domain_writable_status,
              domain_link: v_domain_link,
              img: v_img,
              spin_uid: v_spin_uid,
              spin_gid: v_spin_gid,
              spin_uid_access_right: v_spin_uid_access_right,
              spin_gid_access_right: v_spin_gid_access_right,
              spin_world_access_right: v_spin_world_access_right,
              spin_updated_at: v_spin_updated_at
          )

        rescue ActiveRecord::StaleObjectError
          if retry_modify_domain > 0
            retry_modify_domain -= 1
            throw :modify_domain_again
          else
            return nil
          end
        end
      end
    }
    return domain_rec
  end

  # => end of create_domain

  def self.delete_domain sid, node_key

    ids = SessionManager.get_uid_gid(sid, true)

    retry_count = ACTIVE_RECORD_RETRY_COUNT

    catch(:delete_domain_again) {

      self.transaction do

        begin
          domain_rec = DomainDatum.find_by(session_id: sid, hash_key: node_key)
          if domain_rec.present?
            domain_rec.destroy
          end
          delDomains = SpinDomain.where(["hash_key = ? AND spin_uid = ? AND spin_gid = ?", node_key, ids[:uid], ids[:gid]])
          if delDomains
            delDomains.each {|da|
              da.destroy
            }
          end
          delAcs = SpinAccessControl.where(["root_node_hashkey = ? AND spin_gid = ?", node_key, ids[:gid]])
          if delAcs
            delAcs.each {|ac|
              ac.destroy
            }
          end
        rescue ActiveRecord::StaleObjectError
          if retry_count > 0
            retry_count -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :delete_domain_again
          else
            return false
          end
        end
      end
    }

    return true
  end

  # => end of delete_domain

  def self.secret_files_add_domain sid, node_key
    ret = {}
    ns = self.readonly.find_by_sql(['select * from spin_domains where spin_domain_name = ? and domain_root_node_hashkey = ? and spin_gid = ?', folder_rec[:node_name], node_key, ids[:gid]])
    if (ns.count > 0)
      ret[:success] = false
      ret[:errors] = "同じ名前のドメインが存在していますので、既存のドメイン名を変更した上で追加してください。"
      return ret
    end
    did = SpinDomain.maximum(:spin_did) + 1
    folder_rec = SpinNode.readonly.find_by_spin_node_hashkey node_key
    if folder_rec.blank?
      ret[:success] = false
      ret[:errors] = "No folder"
      return ret
    end
    ids = SessionManager.get_uid_gid(sid, true)
    new_mem = {:member_id => ids[:uid]}
    gids = [new_mem]

    #seed = String.new
    #hash_key = String.new
    #if paramshash[:seed]
    #  seed = paramshash[:seed]
    #end
    seed = Random.new
    r = Random.new
    hash_key = Security.hash_key_s seed.rand.to_s + Time.now.to_s + r.rand.to_s
    ret = {}
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      new_domain = self.new
      new_domain[:spin_did] = did
      new_domain[:spin_domain_name] = folder_rec[:node_name]
      new_domain[:spin_domain_root] = folder_rec[:virtual_path]
      new_domain[:spin_domain_disp_name] = folder_rec[:node_name]
      new_domain[:domain_root_node_hashkey] = folder_rec[:spin_node_hashkey]
      new_domain[:hash_key] = hash_key
      new_domain[:spin_server] = 'localhost'
      new_domain[:domain_writable_status] = true
      new_domain[:domain_link] = 'file_type_icon/Drawer.png'
      new_domain[:img] = 'file_type_icon/Drawer.png'
      new_domain[:spin_uid] = ids[:uid]
      new_domain[:spin_gid] = ids[:gid]
      new_domain[:spin_uid_access_right] = 15
      new_domain[:spin_gid_access_right] = 7
      new_domain[:spin_world_access_right] = 0
      new_domain[:spin_updated_at] = Time.now

      new_domain.save

      SpinAccessControl.secret_files_add_domain_access_control(sid, folder_rec[:spin_node_hashkey], 7, gids, 32768, hash_key)
    end
    ret[:success] = true
    ret[:spin_domain_name] = folder_rec[:node_name]
    ret[:spin_did] = did
    ret[:spin_domain_disp_name] = folder_rec[:node_name]
    ret[:hash_key] = hash_key
    ret[:spin_domain_root] = folder_rec[:virtual_path]
    ret[:domain_root_node_hashkey] = folder_rec[:spin_node_hashkey]
    return ret
  rescue => e
    ret[:success] = false
    ret[:errors] = e.messages
    return ret

  end

  # => end of create_domain

  def self.secret_files_delete_domain sid, node_key

    #domain_rec = SpinDomain.find(:first, :conditions=>["session_id = ? AND hash_key = ?", sid, node_key] )
    ret = {}
    ids = SessionManager.get_uid_gid(sid, true)
    #delDomains = SpinDomain.where(["domain_root_node_hashkey = ? AND spin_uid = ? AND spin_gid = ?", node_key, ids[:uid], ids[:gid]] )
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      #delDomains = SpinDomain.where(["domain_root_node_hashkey = ? AND spin_uid = ? AND spin_gid = ?", domain_rec[:spin_domain_hash_key], ids[:uid], ids[:gid]] )
      #delDomains = SpinDomain.where(["domain_root_node_hashkey = ? AND spin_uid = ? AND spin_gid = ?", node_key, ids[:uid], ids[:gid]] )
      delDomains = SpinDomain.where(["hash_key = ? AND spin_uid = ? AND spin_gid = ?", node_key, ids[:uid], ids[:gid]])
      @delDomainsCount = delDomains.count
      if (@delDomainsCount == 1)
        managed_node_hashkey = delDomains[0][:domain_root_node_hashkey]
      end
      if delDomains.present?
        delDomains.each {|da|
          da.delete
        }
        delAcs = SpinAccessControl.where(["managed_node_hashkey = ? AND spin_gid = ?", managed_node_hashkey, ids[:gid]])
        if delAcs.present?
          delAcs.each {|ac|
            ac.delete
          }
        end
      end
    end
    ret[:success] = true
    ret[:count] = @delDomainsCount
    return ret
  rescue => e
    ret[:success] = false
    ret[:errors] = e.messages
    return ret

  end

  # => end of delete_domain

  def self.secret_files_is_domain sid, managed_node_key

    #domain_rec = SpinDomain.find(:first, :conditions=>["session_id = ? AND hash_key = ?", sid, node_key] )
    ret = {}
    ids = SessionManager.get_uid_gid(sid, true)
    domains = SpinDomain.where(["domain_root_node_hashkey = ? AND spin_uid = ? AND spin_gid = ?", managed_node_key, ids[:uid], ids[:gid]])
    ret[:domains] = {}
    domains.each_with_index {|dm, index|
      ret[:domains][index] = {}
      ret[:domains][index][:spin_did] = dm[:spin_did]
      ret[:domains][index][:spin_domain_name] = dm[:spin_domain_name]
      ret[:domains][index][:spin_domain_root] = dm[:spin_domain_root]
      ret[:domains][index][:domain_descr] = dm[:domain_descr]
      ret[:domains][index][:spin_domain_disp_name] = dm[:spin_domain_disp_name]
      ret[:domains][index][:domain_root_node_hashkey] = dm[:domain_root_node_hashkey]
      ret[:domains][index][:hash_key] = dm[:hash_key]
      ret[:domains][index][:spin_uid] = dm[:spin_uid]
      ret[:domains][index][:spin_gid] = dm[:spin_gid]
      ret[:domains][index][:spin_uid_access_right] = dm[:spin_uid_access_right]
      ret[:domains][index][:spin_gid_access_right] = dm[:spin_gid_access_right]
      ret[:domains][index][:spin_world_access_right] = dm[:spin_world_access_right]
    }
    #ret[:count]   = index;
    ret[:success] = true
    return ret
  end # => end of is_domain

end
