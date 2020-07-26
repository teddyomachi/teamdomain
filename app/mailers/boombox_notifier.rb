class BoomboxNotifier < ActionMailer::Base
  default :from => 'filemanager@secretfiles.net'

  def welcome(recipient)
    @recipient = recipient
    mail(:to => recipient,
         :subject => "[Signed up] Welcome #{recipient}")
  end
  
  def upload_info(sid,mail_to,folder_vpath,file_vpath,file_size_s,user_name,download_url,thumbnail_path = '')
    subject_string = "[BOOMBOX通知]ファイルがアップロードされました"
    @user = {}
    @vpath = {}
    @user[:name] = user_name
    @vpath[:folder_vpath] = folder_vpath
    @vpath[:file_vpath] = file_vpath
    @file_size = file_size_s
    @url = download_url
    
    @mail_to_rec = mail_to
    @sid_rec = sid
    
    unless thumbnail_path.empty?
      file_name = file_vpath[(folder_vpath.length + 1)..-1]
      attachments.inline["#{file_name}"] = File.read(thumbnail_path)
    end
    
    mail( :to => mail_to, :subject => subject_string )
  end
  
  def modification_info(sid,mail_to,folder_vpath,file_vpath,file_size_s,user_name,download_url,thumbnail_path = '')
    subject_string = "[BOOMBOX通知]ファイルが更新されました"
    @user = {}
    @vpath = {}
    @user[:name] = user_name
    @vpath[:folder_vpath] = folder_vpath
    @vpath[:file_vpath] = file_vpath
    @file_size = file_size_s
    @url = download_url
    
    @mail_to_rec = mail_to
    @sid_rec = sid
    
    unless thumbnail_path.empty?
      file_name = file_vpath[(folder_vpath.length + 1)..-1]
      attachments.inline["#{file_name}"] = File.read(thumbnail_path)
    end
    
    mail( :to => mail_to, :subject => subject_string )
  end
  
  def delete_info(sid,mail_to,folder_vps,trashed_vps,user_name)
    subject_string = "[BOOMBOX通知]ファイルが削除されました"
    @user = {}
    @vpath_list = []
    @user[:name] = user_name
    @folder_vpath = folder_vps
    @vpath_list = trashed_vps
    trashed_vps.each {|tvp|
      @vpath_list.push(tvp + "\n")
    }
    
    @mail_to_rec = mail_to
    @sid_rec = sid
    
    mail( :to => mail_to, :subject => subject_string )
  end
  
  def send_url_link(addr,url_list)
    subject_string = "[BOOMBOX通知]URLリンク送信"
    $urlLink=url_list;

      mail( :to => addr, :subject => subject_string )
#    for i in 0..(addr.size - 1) do
#      mail( :to => addr[i], :subject => subject_string )
#    end
  end
  
end
