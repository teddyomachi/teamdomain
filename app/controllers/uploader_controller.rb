# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'const/ssl_const'
require 'openssl'
require 'base64'
require 'uri'
require 'json'
require 'pp'

class UploaderController < ApplicationController
  include Vfs
  include Acl
  include Stat
  include Ssl
  
  def put
  end
  
  def upload_proc
    # decode file_manager_args
    rsa_key_pem = SpinNode.get_root_rsa_key
    # params.each {|ps|
      # pp ps
      # }
    upload_file_params = params[:upload_file]
    # pp upload_file_params
    rdr_params = params[:fmargs]
    fmargs64 = Security.unescape_base64 params[:fmargs]
    upload_params = fmargs64
    # upload_params = Base64.decode64 fmargs64
    file_manager_args = Security.private_key_decrypt_decode64 rsa_key_pem, upload_params
    ssid = file_manager_args[0..39]
    hkey = file_manager_args[40..79]
    file_name = file_manager_args[80..-1]
    # File.open("public/original_data/#{file_name}", "wb") { |f| f << file_name.read }
    # put local
    upfile = upload_file_params.tempfile
    name = upload_file_params.original_filename
    fname = name.gsub(" ","\ ")
    if (out_file = File.open "#{File.dirname(__FILE__)}/../../public/original_data/#{fname}", "wb")
      out_file << upfile.read
      out_file.close
    else
      result_hash = { :success => false, :status => ERROR_UPLOAD_FILE, :errors => "upload #{fname} failed!" }
      render :json => result_hash
    end
    # result = "#{File.dirname(__FILE__)}/../../public/original_data/#{name} is uploaded"        
    # file_path = "#{File.dirname(__FILE__)}/../../public/secret_files/spin/file_listA.sfl"
    # file_path_unix = "#{File.dirname(__FILE__)}/../../public/secret_files/spin/file_listA.sfl".gsub(' ','\\ ')
    result_string = "public/original_data/#{fname} is uploaded"
    rdr_uri = '/secret_files/secret_files/multipart_form?fmargs=' + rdr_params
    result_hash = { :success => true, :status => INFO_UPLOAD_FILE_SUCCESS, :result => result_string }
    # render :json => result_hash
    render :text => result_hash.to_json
  end

  def xupload_proc
    my_session_id = flash[:notice]
    sc = SpinSession.find_by_spin_session_id my_session_id
    if sc
      my_params = JSON.parse sc.spin_session_params
    else
      return { :success => false, :status => false, :errors => "パラメータの取得に失敗しました"}
    end
    
    fn = my_params['upload_filename']
    upfilename = my_params[:upfile]
    name = fn['original_filename']
    File.open("#{File.dirname(__FILE__)}/../../public/original_data/#{name}", "wb") { |f| f << upfilename.read }
    result = "#{File.dirname(__FILE__)}/../../public/original_data/#{name} is uploaded"
    
    
    file_path = "#{File.dirname(__FILE__)}/../../public/secret_files/spin/file_listA.sfl"
    file_path_unix = "#{File.dirname(__FILE__)}/../../public/secret_files/spin/file_listA.sfl".gsub(' ','\\ ')
    
    # puts file_path_unix
    
    myjson = File.read(file_path)
    
    jj = JSON.parse(myjson)
    
    puts jj["total"]
    
    n = jj["total"].to_i + 1
    
    newjson = File.open("new.json", "w")
    
    newjson << "{\n\t\"success\": true,\n\t\"total\": "
    newjson << n
    newjson << ",\n"
    newjson << "\"files\": [\n"
    
    newfilename = name
    newfiletype = "mp4"
    person_in_charge = "清藤泰彦"
    new_c_date = Time.now - 2.weeks
    new_u_date = Time.now
    new_p_date = Time.now
    
    jobj =    {
          "folder_hash_key" => "2001:0db8:bd05:01d2:288a:1fc0:0001:20e3",
          "folder_readable_status" => true,
          "folder_writable_status" => true,
          "hash_key" => "2001:0db8:bd05:01d2:288a:1fc0:0001:58ec",
          "cont_location" => "folder_a",
          "file_readable_status" => true,
          "file_writable_status" => true,
          "file_name" => "#{newfilename}",
          "file_type" => "mp4",
          "file_size" => "",
          "file_exact_size" => "",
          "file_version" => "",
          "url" => "../original_data/#{newfilename}",
          "icon_image" => "file_type_icon/mpeg.png",
          "thumbnail_image" => "thumbnail_image/#{newfilename}.png",
          "created_date" => "#{new_c_date}",
          "creator" => "#{person_in_charge}",
          "modified_date" => "#{new_u_date}",
          "modifier" => "#{person_in_charge}",
          "owner" => "#{person_in_charge}",
          "ownership" => "me",
          "control_right" => "false",
          "lock" => "0",
          "id_lc_by" => "",
          "name_lc_by" => "",
          "dirty" => "true",
          "open_status" => false,
          "access_group" => "自分",
          "title" => "北のカナリアたち",
          "subtitle" => "",
          "frame_size" => "",
          "duration" => "",
          "producer" => "-",
          #"produced_date" => "#{new_p_date}",
          "produced_date" => "",
          "location" => "-",
          "cast" => "-",
          "client" => "",
          "copyright" => "",
          "music" => "",
          "keyword" => "北のカナリアたち",
          "description" => "北のカナリアたち",
          "details" => ""
        }
    
    newjson << jobj.to_json
    jj["files"].each {|j|
      newjson << ",\n"
      newjson << j.to_json
    }
    
    newjson << "\n]\n}\n"
    
    newjson.close
    
    ret = `./from18to19.sh new.json #{file_path_unix}`
   
    render :text => "{:success => true, :file => '#{name}'}"
  end
end
