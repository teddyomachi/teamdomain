class FsmanagerController < ApplicationController
  
  def self.spin_api_request_proc
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
end
