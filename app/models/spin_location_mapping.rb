class SpinLocationMapping < ActiveRecord::Base
  # attr_accessor :title, :body
  def self.delete_mapping_data node_hash_key
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:delete_mapping_data_again){
  
      self.transaction do
        begin
          #      self.find_by_sql("LOCK TABLE spin_location_mappings IN EXCLUSIVE MODE;")
          slms = self.where(["node_hash_key = ?",node_hash_key])
          slms.each {|slm|
            #            slm.destroy
            #        slm.with_lock do
            #          begin
            slm[:is_void] = true
            slm.save
            #          rescue
            #            next
            #          end     
            #        end
          }      
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :delete_mapping_data_again
        end
      end
      #    ActiveRecord::Base.lock_optimistically = true
    }
  end

  def self.get_mapping_data node_hash_key
    ActiveRecord::Base.lock_optimistically = false
    #self.transaction do
    slms = self.readonly.where(["node_hash_key = ?",node_hash_key])
    if slms.count != 1
      return ERROR_BOOMBOX_API_GET_MAPPING_DATA_SLM_COUNT
    end
    lp = slms[0][:location_path]
    return lp
    #end
    ActiveRecord::Base.lock_optimistically = true
  end
  
  def self.change_wos_server org, new
    slms = self.where(["id > 0"])
    slms.each {|s|
      sl = s[:location_path]
      sl.sub!(org,new)
      s[:location_path] = sl
      s.save
      FileManager.rails_logger(s[:location_path])
    }
  end
  
end # => end of class SpinLoactionMapping
