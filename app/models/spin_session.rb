class SpinSession < ActiveRecord::Base
  attr_accessor :selected_domain_a, :selected_domain_b, :selected_folder_a, :selected_folder_b, :last_access, :cont_location, :cont_location_domain, :cont_location_folder, :cont_location_file_list, :session_expire, :session_status, :spin_domaindata_A_id, :spin_domaindata_B_id, :spin_filedata_id, :spin_folderdata_B_id, :spin_folderdata_A_id, :spin_groupdata_id, :spin_last_login, :spin_last_logout, :spin_login_time, :spin_memberdata_id, :spin_operatordata_id, :spin_recycledata_id, :spin_search_condition_id, :spin_search_option_id, :spin_senderdata_id, :spin_session_id, :spin_session_data, :spin_current_directory, :spin_current_domain, :spin_uid, :spin_uname, :spin_agent_type, :spin_agent_name
  
end
