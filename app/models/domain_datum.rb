# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'tasks/session_management'
require 'tasks/security'
require 'utilities/set_utilities'
require 'utilities/database_utilities'

class DomainDatum < ActiveRecord::Base
  include Vfs
  include Acl

  attr_accessor :selected, :current_folder, :cont_location, :domain_link, :domain_name, :domain_writable_status, :folder_hash_key, :hash_key, :spin_domain_hash_key, :img, :spin_did, :session_id

  def self.fill_domain_data_table ssid, my_uid, location, my_domains, mtime
    # get my group id
    my_gids = SpinGroupMember.get_user_groups my_uid

    in_trash_flag = 0

    default_domain = nil
    c_domains = Array.new
    default_domain = SpinUser.get_default_domain ssid
    if default_domain.present?
      c_domains.push default_domain
    end

    c_domains = SpinDomain.search_accessible_domains ssid, my_gids

    if c_domains.size > 0 and my_domains.size > 0
      c_domains.each {|de|
        my_domains.each {|me|
          if de[:hash_key] == me[:hash_key]
            if de[:updated_at] > me[:updated_at]
              de.destroy
            else
              c_domains.delete(de)
            end
          end
        }
      }
    end

    #    unless c_domains.length > 0
    #      rethash = {:success => false, :status => false, :errors => "ドメインが有りません"}
    #      return rethash
    #    end

    # build DomainData
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    saved_records = 0
    #    DomainDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    catch(:fill_domain_data_table_again) {
      self.transaction do
        begin
          if c_domains.size > 0

            c_domains.each {|d|
              in_trash_flag = 0
              if d[:spin_domain_name] != 'personel'
                begin
                  sn = SpinNode.find_by_spin_node_hashkey d[:domain_root_node_hashkey]
                  if sn.present? and sn[:in_trash_flag] == true
                    in_trash_flag = 1
                  end
                rescue ActiveRecord::RecordNotFound
                  next
                end
              end
              # is there domain record in DomainData?
              #        r = Random.new
              #        dd_key = Security.hash_key_s( d[:hash_key] + location + d[:id].to_s + r.rand.to_s )
              #        dd = DomainDatum.find_by_spin_domain_hash_key_and_cont_location d[:hash_key], location
              if in_trash_flag != 1
                #            dd = DomainDatum.find_by_session_id_and_spin_domain_hash_key_and_cont_location ssid, d[:hash_key], location
                #      if dd == nil and ( d_acl >= ACL_NODE_READ or d_gacl > ACL_NODE_NO_ACCESS ) # => match!
                #            if dd == nil
                new_domain_datum = DomainDatum.create {|nd|
                  nd[:session_id] = ssid
                  nd[:spin_did] = d[:spin_did]
                  nd[:hash_key] = d[:hash_key]
                  nd[:spin_domain_hash_key] = d[:hash_key]
                  nd[:selected_folder] = ''
                  nd[:current_folder] = ''
                  nd[:folder_hash_key] = d[:domain_root_node_hashkey]
                  begin
                    nd[:vpath] = SpinNode.get_vpath(d[:domain_root_node_hashkey])
                  rescue ActiveRecord::RecordNotFound
                    nd[:vpath] = '/'
                  end
                  nd[:cont_location] = location
                  nd[:domain_writable_status] = d[:domain_writable_status]
                  nd[:domain_name] = d[:spin_domain_disp_name]
                  nd[:domain_link] = d[:domain_link]
                  nd[:img] = d[:img]
                  nd[:created_at] = mtime
                  nd[:updated_at] = mtime
                  nd[:spin_updated_at] = mtime
                  nd[:selected] = SessionManager.is_selected_domain ssid, d[:hash_key], location
                  #                new_domain_datum.save # => save = update database
                }

                saved_records += 1
                #            else # => there already is!
                #              dd[:session_id] = ssid
                #              if dd.save
                #                saved_records += 1
                #              end
                #            end # => end of if
              end
            } # => end of c_domains block
          end
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :fill_domain_data_table_again
          else
            return {:success => false, :status => false, :errors => 'Failed to fil domain_data'}
          end
        end

      end # => end of trasnaction
    }

    return {:success => true, :status => true, :result => saved_records}
  end

  def self.fill_domains ssid, location
    # get uid and gid
    my_uid = SessionManager.get_uid ssid
    rethash = Hash.new
    #    d_location = location.gsub "folder_", "domain_"
    my_domains = Array.new

    my_domains_can = self.where(["session_id = ?", ssid])

    my_domains_can.each do |dc|
      if SpinDomain.is_accessible_domain ssid, dc[:hash_key]
        my_domains.push dc
      end
    end

    # check update
    last_update_time = nil
    my_domains.each {|d|
      if last_update_time == nil # => set initial value
        last_update_time = d[:updated_at]
      elsif last_update_time < d[:updated_at] # => change value
        last_update_time = d[:updated_at]
      end
    }
    #      if DatabaseUtility::StateUtility.is_updated_after 'SpinDomain', last_update_time # => it needs update
    #        my_domains.each { |d| d.destroy }
    #      end 
    rethash = self.fill_domain_data_table ssid, my_uid, location, my_domains, Time.now

    return rethash
  end

  # => end of fill_domains

  def self.get_domain_display_data ssid, location
    return_data_list = Array.new;
    domains = Array.new

    begin
      domains = DomainDatum.where(["session_id = ? AND cont_location = ?", ssid, location]).order("spin_did")
      domains.each {|target|
        folder_hash_key = target[:folder_hash_key];
        #domain_vpath = SpinNode.where(:spin_node_hashkey => folder_hash_key);
        domain_vpath = nil
        begin
          domain_vpath = SpinNode.select("virtual_path").find_by_spin_node_hashkey(folder_hash_key);
          if domain_vpath.blank?
            return return_data_list
          end
          if domain_vpath.present?
            target[:vpath] = domain_vpath[:virtual_path].present? ? domain_vpath[:virtual_path] : '';
          else
            target[:vpath] = '';
          end
          return_data_list.push(target);
        rescue ActiveRecord::RecordNotFound
          target[:vpath] = '';
          return_data_list.push(target);
        end
      }
    rescue ActiveRecord::RecordNotFound
      return return_data_list;
    end

    return return_data_list;
  end

  # => end of get_domain_display_data

  def self.select_domain sid, domain_key = nil, location = 'folder_a'
    my_domain = nil
    rethash = {:success => false, :domain_root_node => ""}

    if domain_key.blank?
      my_domain = SpinDomain.find_by(spin_domain_name: 'personel')
      if my_domain.blank?
        return rethash
      end
      domain_key = my_domain[:hash_key]
    else
      my_domain = SpinDomain.find_by(hash_key: domain_key)
      if my_domain.blank?
        return rethash
      end
    end

    DomainDatum.transaction do
      self.where(selected: true, session_id: sid).update_all(selected: false)
    end

    dom = nil
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:select_domain_again) {
      DomainDatum.transaction do
        begin

          case location
          when 'folder_a'
            dom = self.find_by(session_id: sid, spin_domain_hash_key: domain_key, cont_location: 'folder_a')
          when 'folder_b'
            dom = self.find_by_session_id_and_spin_domain_hash_key_and_cont_location sid, domain_key, 'folder_b'
          end

          if dom.blank?
            return {:success => false, :status => false, :errors => 'Failed to find domain'}
          end

          domr = nil
          dom_is_dirty = false
          domr = SpinDomain.find_by(hash_key: domain_key)
          if domr.blank?
            dom_is_dirty = true
          elsif domr[:spin_updated_at] > dom[:spin_updated_at]
            dom_is_dirty = true
          else
            dom_is_dirty = false
          end
          self.where(session_id: sid, spin_domain_hash_key: domain_key, cont_location: 'folder_a').update_all(is_dirty: dom_is_dirty, selected: true)

          rethash[:success] = true
          rethash[:domain_root_node] = domr[:domain_root_node_hashkey]
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :select_domain_again
          else
            retd = DatabaseUtility::SessionUtility.set_current_domain sid, domain_key, location
            return {:success => false, :status => false, :errors => 'Failed to fil domain_data'}
          end

        end # => end of begin block
      end # => end of transaction
    }

    retd = DatabaseUtility::SessionUtility.set_current_domain sid, domain_key, location
    return rethash
  end

  # => end of select_domain

  def self.set_selected_folder sid, domain_key, folder_hashkey, location
    cdom = nil
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    rethash = {:success => false, :selected_folder => ""}
    catch(:set_selected_folder_again) {
      DomainDatum.transaction do
        begin

          case location
          when 'folder_a'
            #            cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, domain_key, 'folder_a'
            #            if cdom.blank?
            #              return nil
            #            end
            recs = DomainDatum.where(session_id: sid, hash_key: domain_key, cont_location: 'folder_a').update_all(selected_folder_a: folder_hashkey, selected_folder: folder_hashkey, current_folder: folder_hashkey)
            unless recs > 0
              return nil
            end
            rethash[:selected_folder] = folder_hashkey
            rethash[:success] = true
            #            cdom[:selected_folder_a] = folder_hashkey
            #            cdom[:selected_folder] = folder_hashkey
          when 'folder_b'
            cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, domain_key, 'folder_b'
            if cdom.present?
              cdom[:selected_folder_b] = folder_hashkey
              cdom[:selected_folder] = folder_hashkey
            end
          when 'folder_at'
            begin
              cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, domain_key, 'folder_a'
              if cdom.present?
                cdom[:selected_folder_at] = folder_hashkey
                cdom[:selected_folder] = folder_hashkey
              end
            rescue ActiveRecord::RecordNotFound
              return cdom
            end
          when 'folder_bt'
            begin
              cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, domain_key, 'folder_b'
              if cdom.present?
                cdom[:selected_folder_bt] = folder_hashkey
                cdom[:selected_folder] = folder_hashkey
              end
            rescue ActiveRecord::RecordNotFound
              return cdom
            end
          when 'folder_atfi'
            begin
              cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, domain_key, 'folder_a'
              if cdom.present?
                cdom[:selected_folder_atfi] = folder_hashkey
                cdom[:selected_folder] = folder_hashkey
              end
            rescue ActiveRecord::RecordNotFound
              return cdom
            end
          when 'folder_btfi'
            begin
              cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, domain_key, 'folder_b'
              if cdom.present?
                cdom[:selected_folder_btfi] = folder_hashkey
                cdom[:selected_folder] = folder_hashkey
              end
            rescue ActiveRecord::RecordNotFound
              return cdom
            end
          else
            recs = DomainDatum.where(session_id: sid, hash_key: domain_key, cont_location: 'folder_a').update_all(selected_folder_a: folder_hashkey, selected_folder: folder_hashkey, current_folder: folder_hashkey)
            unless recs > 0
              return nil
            end
          end
          #          cdom.save
          rethash[:success] = true
          rethash[:selected_folder] = folder_hashkey
            #          rethash[:selected_folder] = cdom[:selected_folder]
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_selected_folder_again
          else
            return {:success => false, :status => false, :errors => 'Failed to select folder'}
          end

        end # => end of begin block
      end # => end of transaction
    }
    return rethash
    #      pp cdom
  end

  # end of set_selected_folder folder_hashkey, location

  def self.has_updated sid, domain_key, target_obj = 'folder'
    #    DomainDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    fol = nil
    d_is_dirty = false
    d_is_new = false
    t_is_dirty = false
    t_is_new = false
    recs = 0

    retry_has_updated = ACTIVE_RECORD_RETRY_COUNT
    catch(:has_updated_again) {
      DomainDatum.transaction do
        begin
          fol = self.find_by_session_id_and_hash_key sid, domain_key
          if fol.blank?
            return false
          end
          fol[:spin_updated_at] = Time.now
          if target_obj == 'folder'
            d_is_dirty = true
            d_is_new = false
          else # => then 'target_folder'
            t_is_dirty = true
            t_is_new = false
          end
          recs = DomainDatum.where(session_id: sid, hash_key: domain_key).update_all(is_dirty: d_is_dirty, is_new: d_is_new, target_is_dirty: t_is_dirty, target_is_new: t_is_new)
        rescue ActiveRecord::StaleObjectError
          if retry_has_updated > 0
            retry_has_updated -= 1
            throw :has_updated_again
          else
            return false
          end
        end
      end # => end of transaction
    }
    if recs.blank?
      return false
    end

    unless recs > 0
      return false
    else
      return true
    end
  end

  # => end of self.has_updated sid, folder_key

  def self.get_selected_folder sid, target_domain, cont_location
    cdom = nil
    cfol = nil
    begin
      case cont_location
      when 'folder_a'
        cdom = self.find_by(session_id: sid, hash_key: target_domain, cont_location: 'folder_a')
        if cdom.blank?
          return nil
        end
        if cdom[:selected_folder_a].blank?
          cfol = FolderDatum.get_selected_folder_of_domain(sid, target_domain, cont_location)
          if cfol.blank?
            cfol = FolderDatum.get_first_folder_of_domain(sid, target_domain, cont_location)
            if cfol.blank?
              FolderDatum.fill_folders(sid, cont_location, target_domain)
              cfol = FolderDatum.get_first_folder_of_domain(sid, target_domain, cont_location)
            end
          end
        else
          cfol = cdom[:selected_folder_a]
        end
        return cfol
      when 'folder_b'
        cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, target_domain, 'folder_b'
        if cdom.blank?
          return nil
        end
        return cdom[:selected_folder_b]
      when 'folder_at'
        cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, target_domain, 'folder_a'
        if cdom.blank?
          return nil
        end
        return cdom[:selected_folder_at]
      when 'folder_bt'
        cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, target_domain, 'folder_b'
        if cdom.blank?
          return nil
        end
        return cdom[:selected_folder_bt]
      when 'folder_atfi'
        cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, target_domain, 'folder_a'
        if cdom.blank?
          return nil
        end
        return cdom[:selected_folder_atfi]
      when 'folder_btfi'
        cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, target_domain, 'folder_b'
        if cdom.blank?
          return nil
        end
        return cdom[:selected_folder_btfi]
      else
        cdom = self.find_by_session_id_and_hash_key_and_cont_location sid, target_domain, 'folder_a'
        if cdom.blank?
          return nil
        end
        return cdom[:selected_folder_a]
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return cfol
  end

  # end of get_selected_folder sid, target_domain, cont_location

  def self.set_domains_dirty node_rec
    # set is_dirty flag on domains to which the node belongs
    # find domains in which node_key is
    domains = SpinLocationManager.search_domains_of_node node_rec
    retry_set_domains_dirty = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_domains_dirty_again) {
      DomainDatum.transaction do
        begin
          domains.each {|dm|
            ds = self.where :hash_key => dm, :is_dirty => false
            ds.each {|dom|
              dom[:is_dirty] = true
              dom.save
            }

            ds = self.where :hash_key => dm, :is_new => true
            ds.each {|dom|
              dom[:is_new] = false
              dom.save
            }
          }
        rescue ActiveRecord::StaleObjectError
          retry_set_domains_dirty -= 1
          if retry_set_domains_dirty > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_domains_dirty_again
          else
            return false
          end
        end
      end # => end of transaction
    }
    return true
  end

  # => end of set_domains_dirty

  def self.set_domains_dirty_by_key node_key
    # set is_dirty flag on domains to which the node belongs
    # find domains in which node_key is
    domains = SpinLocationManager.search_domains_of_node_by_key node_key
    retry_set_domains_dirty_by_key = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_domains_dirty_by_key_again) {
      DomainDatum.transaction do
        begin
          domains.each {|dm|
            begin
              ds = self.where :hash_key => dm, :is_dirty => false
              ds.each {|dom|
                dom[:is_dirty] = true
                dom.save
              }
            rescue ActiveRecord::RecordNotFound
            end

            begin
              ds = self.where :hash_key => dm, :is_new => true
              ds.each {|dom|
                dom[:is_new] = false
                dom.save
              }
            rescue ActiveRecord::RecordNotFound
            end
          }
        rescue ActiveRecord::StaleObjectError
          retry_set_domains_dirty_by_key -= 1
          if retry_set_domains_dirty_by_key > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_domains_dirty_by_key_again
          else
            return false
          end
        end
      end
    }
    return true
  end

  # => end of set_domains_dirty

  def self.unset_domains_dirty node_rec
    # find domains in which node_key is
    retry_unset_domains_dirty = ACTIVE_RECORD_RETRY_COUNT
    catch(:unset_domains_dirty_again) {
      DomainDatum.transaction do
        begin
          domains = SpinLocationManager.search_domains_of_node node_rec
          domains.each {|dm|
            ds = self.where :hash_key => dm
            ds.each {|dom|
              dom[:is_dirty] = false
              dom[:is_new] = false
              dom.save
            }
          }
        rescue ActiveRecord::StaleObjectError
          retry_unset_domains_dirty -= 1
          if retry_unset_domains_dirty > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :unset_domains_dirty_again
          else
            return false
          end
        end
      end
    }
    return true
  end

  # => end of set_domains_dirty

  def self.unset_domains_dirty_by_key node_key
    # find domains in which node_key is
    retry_unset_domains_dirty_by_key = ACTIVE_RECORD_RETRY_COUNT
    catch(:unset_domains_dirty_by_key_again) {
      DomainDatum.transaction do
        begin
          domains = SpinLocationManager.search_domains_of_node_by_key node_key
          domains.each {|dm|
            ds = self.where :hash_key => dm
            ds.each {|dom|
              dom[:is_dirty] = false
              dom[:is_new] = false
              dom.save
            }
          }
        rescue ActiveRecord::StaleObjectError
          if retry_unset_domains_dirty_by_key > 0
            retry_unset_domains_dirty_by_key -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :unset_domains_dirty_by_key_again
          else
            return false
          end
        end
      end
    }
    return true
  end

  # => end of set_domains_dirty

  def self.set_domain_dirty sid, cont_location, spin_domain_key
    # set is_dirty flag on the domain datum which is spin_domain specified by spin_domain_key
    location = cont_location
    case cont_location
    when 'folder_a', 'folder_at', 'folder_atfi'
      location = 'folder_a'
    when 'folder_b', 'folder_bt', 'folder_btfi'
      location = 'folder_b'
    end # => end of case
    d = nil
    retry_set_domain_dirty = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_domain_dirty_again) {
      DomainDatum.transaction do
        begin
          d = self.find_by_session_id_and_cont_location_and_spin_domain_hash_key sid, location, spin_domain_key
          if d.blank?
            return false
          end
          d[:is_dirty] = true
          d.save
        rescue ActiveRecord::StaleObjectError
          retry_set_domain_dirty -= 1
          if retry_set_domain_dirty > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_domain_dirty_again
          else
            return false
          end
        end
      end
    }
    return true
  end

  # => end of set_domains_dirty

  def self.unset_domain_dirty sid, cont_location, spin_domain_key
    location = cont_location
    case cont_location
    when 'folder_a', 'folder_at', 'folder_atfi'
      location = 'folder_a'
    when 'folder_b', 'folder_bt', 'folder_btfi'
      location = 'folder_b'
    end # => end of case
    d = nil
    retry_unset_domain_dirty = ACTIVE_RECORD_RETRY_COUNT
    catch(:unset_domain_dirty_again) {
      #    DomainDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      DomainDatum.transaction do
        begin
          d = self.find_by_session_id_and_cont_location_and_spin_domain_hash_key sid, location, spin_domain_key
          if d.blank?
            return false
          end
          d.update(is_dirty: false)
        rescue ActiveRecord::StaleObjectError
          if retry_unset_domain_dirty > 0
            retry_unset_domain_dirty -= 1
            throw :unset_domain_dirty_again
          else
            return false
          end
        end
      end
    }
    return true
  end

  # => end of set_domains_dirty

  def self.is_dirty_domain sid, cont_location, domain_key
    location = cont_location
    case cont_location
    when 'folder_a', 'folder_at', 'folder_atfi'
      location = 'folder_a'
    when 'folder_b', 'folder_bt', 'folder_btfi'
      location = 'folder_b'
    end # => end of case
    d = nil
    #    DomainDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    DomainDatum.transaction do
      begin
        d = self.find_by_session_id_and_cont_location_and_hash_key sid, location, domain_key
        if d.blank?
          return true
        end
      rescue ActiveRecord::RecordNotFound
        return true
      end
    end
    return d[:is_dirty]
  end

  # => end of is_dirty_domain domain_key

  def self.domains_have_updated sid, domain_hks
    unless domain_hks.length > 0
      return domain_hks.length
    end
    #    DomainDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    retry_domains_have_updated = ACTIVE_RECORD_RETRY_COUNT
    catch(:domains_have_updated_again) {
      DomainDatum.transaction do
        begin
          uds = self.where :session_id => sid, :hash_key => domain_hks
          ts = Time.now
          uds.each {|d|
            d[:spin_updated_at] = ts
            d[:is_dirty] = true
            d[:is_new] = false
            d.save
          }
        rescue ActiveRecord::StaleObjectError
          if retry_domains_have_updated > 0
            retry_domains_have_updated -= 1
            throw :domains_have_updated_again
          else
            return -1
          end
        end
      end
    }
    return domain_hks.length
  end # =>  end of self.domains_have_updated

end
