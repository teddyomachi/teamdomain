# # Rails.application.routes.draw do
#   if Rails.env.development?
#     mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
#   end
#   post "/graphql", to: "graphql#execute"
# #   For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
# # end

Rails.application.routes.draw do

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"
  resources :spin_vfs_storage_mappings


  resources :spin_vfs_tree_mappings


  resources :spin_virtual_file_systems


  resources :user_interface_managers


  resources :spin_user_attributes


  resources :secrfet_files_login


  resources :spin_objects


  resources :spin_storages


  resources :spin_domains


  resources :spin_sessions


  resources :spin_group_members


  resources :spin_users


  resources :spin_groups


  resources :target_folder_data

  resources :sender_data

  resources :search_option_data

  resources :search_condition_data

  resources :recycler_data

  resources :operator_data

  resources :member_data

  resources :group_data

  resources :folder_data

  resources :file_data

  resources :domain_data

  resources :secret_files_sessions

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  #  root :to => 'welcome#index'
  #  root :to => 'blackhole#reject_proc'

  # See how all your raoutes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  #match 'secret_files_login/login.php'  => 'secret_files_login#proc_login'
  #match 'secret_files/login.php'  => 'secret_files_login#proc_login'
  #
  get 'hello_world', to: 'hello_world#index'

  get 'secret_files_login/login.tdx'  => 'secret_files_login#proc_login'
  match 'secret_files/login.tdx'  => 'secret_files_login#proc_login', :via => [:get, :post]
  get 'secret_files_login/activation.php'  => 'secret_files_login#proc_activation'
  #get 'secret_files_login/activation.tdx'  => 'secret_files_login#proc_activation'
  get 'secret_files_login/auth.html'  => 'secret_files_login#proc_secret_files_login_view'
  get 'secret_files_login'  => 'secret_files_login#proc_secret_files_login_view'
  match 'secret_files_login/tdx/updatedata.tdx' => 'secret_files#php', :via => [:get, :post]
  match 'secret_files/tdx/updatedata.tdx' => 'secret_files#php', :via => [:get, :post]
  # get 'secret_files/index.tdx' => 'secret_files#proc_login_view'
  # get 'secret_files/index.html' => 'secret_files#proc_login_view'
  get 'secret_files/uploader/upload_proc' => 'uploader#upload_proc'
  get 'secret_files/downloader/download_proc' => 'downloader#download_proc'
  get 'secret_files/secret_files/spin_api_request' => 'fsmanager#spin_api_request_proc'
  get 'secret_files/secret_files/multipart_form' => 'uploader#filemanager_upload_request'
  post 'secret_files_login/login.tdx'  => 'secret_files_login#proc_login'
  post 'secret_files_login/activation.php'  => 'secret_files_login#proc_activation'
  #post 'secret_files_login/activation.tdx'  => 'secret_files_login#proc_activation'
  post 'secret_files_login/auth.html'  => 'secret_files_login#proc_secret_files_login_view'
  post 'secret_files_login'  => 'secret_files_login#proc_secret_files_login_view'
  match 'secret_files_login/tdx/updatedata.tdx' => 'secret_files#php', :via => [:get, :post]
  match 'secret_files/tdx/updatedata.tdx' => 'secret_files#php', :via => [:get, :post]
  # post 'secret_files/index.tdx' => 'secret_files#proc_login_view'
  # post 'secret_files/index.html' => 'secret_files#proc_login_view'
  post 'secret_files/uploader/upload_proc' => 'uploader#upload_proc'
  post 'secret_files/downloader/download_proc' => 'downloader#download_proc'
  post 'secret_files/secret_files/spin_api_request' => 'fsmanager#spin_api_request_proc'
  post 'secret_files/secret_files/multipart_form' => 'uploader#filemanager_upload_request'
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # => mobile handler
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #  get 'secret_files_ipad/login.php'  => 'secret_files_login#proc_mobile_login'
  get 'secret_files_ipad/login.tdx'  => 'secret_files_login#proc_mobile_login'
  get 'secret_files_ipad/tdx/login.tdx'  => 'secret_files_login#proc_mobile_login'
  get 'secret_files_ipad/tdx/updatedata.tdx' => 'secret_files#php'
  get 'secret_files_ipad'  => 'secret_files_login#proc_secret_files_ipad_login_view'
  #  get 'secret_files_ipad/php/request.php' => 'secret_files#php'
  get 'secret_files_ipad/index.tdx' => 'secret_files#proc_login_view'
  get 'secret_files_ipad/tdx/index.tdx' => 'secret_files#proc_login_view'
  get 'secret_files_ipad/index.html' => 'secret_files#proc_login_view'
  #  get 'secret_files_iphone/login.php'  => 'secret_files_login#proc_mobile_login'
  get 'secret_files_iphone/login.tdx'  => 'secret_files_login#proc_mobile_login'
  get 'secret_files_iphone/tdx/login.tdx'  => 'secret_files_login#proc_mobile_login'
  get 'secret_files_iphone/tdx/updatedata.tdx' => 'secret_files#php'
  get 'secret_files_iphone'  => 'secret_files_login#proc_secret_files_ipad_login_view'
  #  get 'secret_files_iphone/php/request.php' => 'secret_files#php'
  get 'secret_files_iphone/index.tdx' => 'secret_files#proc_login_view'
  get 'secret_files_iphone/tdx/index.tdx' => 'secret_files#proc_login_view'
  get 'secret_files_iphone/index.html' => 'secret_files#proc_login_view'
  # get 'secret_files/thumbnail' => 'thumbnail#thumbnail_generator'
  # get 'secret_files/data/thumbnail_image' => 'thumbnail#thumbnail_view'
  get 'secret_files/spin_api_request' => 'spin_api#request_broker'
  post 'secret_files/spin_api_request' => 'spin_api#request_broker'
  # m2a
  get 'm2a/index.tdx' => 'spin_m2a#proc_login_view'
  get 'm2a/index.html' => 'spin_m2a#proc_login_view'
  # get 'm2a/uploader/upload_proc' => 'uploader#upload_proc'
  # get 'm2a/filemanager/multipart_form' => 'uploader#filemanager_upload_request'
  # display data
  # get 'secret_files/spin/domains.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/domainsA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/domainsB.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/foldersA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/foldersB.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/foldersAT.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/foldersBT.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/foldersATFi.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/foldersBTFi.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/file_listA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/file_listB.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/file_listS.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  # other json data
  get 'secret_files/spin/recycler.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/search_option.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/search_conditions.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/group_list_tree.sfl' => 'filer_display#proc_display_view'
  get 'secret_files/spin/group_list_all.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/group_list_folder.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/group_list_file.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/group_list_created.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/member_list_mygroup.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/mail_senders.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/working_files.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/active_operator.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/group_list_created.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/user_list.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files/spin/select_list.sfl' => 'filer_display#proc_display_view'

  get 'secret_files/spin/clipboards.sfl' => 'filer_display#proc_display_view' # => domain name and attributes

  get 'secret_files/spin/ArchivedData.sfl' => 'filer_display#proc_display_view' #アーカイブ解除
  get 'secret_files/spin/SyncedData.sfl' => 'filer_display#proc_display_view' #同期解除
  get 'secret_files/spin/dlfolders.sfl' => 'filer_display#proc_display_view' #ダウンロード
  get 'secret_files/spin/dlfiles.sfl' => 'filer_display#proc_display_view' #ダウンロード

  # display data
  # get 'secret_files/spin/domains.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/domainsA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/domainsB.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/foldersA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/foldersB.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/foldersAT.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/foldersBT.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/foldersATFi.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/foldersBTFi.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/file_listA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/file_listB.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/file_listS.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  # other json data
  post 'secret_files/spin/recycler.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/search_option.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/search_conditions.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/group_list_tree.sfl' => 'filer_display#proc_display_view'
  post 'secret_files/spin/group_list_all.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/group_list_folder.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/group_list_file.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/group_list_created.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/member_list_mygroup.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/mail_senders.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/working_files.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/active_operator.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/group_list_created.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/user_list.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  post 'secret_files/spin/select_list.sfl' => 'filer_display#proc_display_view'

  post 'secret_files/spin/clipboards.sfl' => 'filer_display#proc_display_view' # => domain name and attributes

  post 'secret_files/spin/ArchivedData.sfl' => 'filer_display#proc_display_view' #アーカイブ解除
  post 'secret_files/spin/SyncedData.sfl' => 'filer_display#proc_display_view' #同期解除
  post 'secret_files/spin/dlfolders.sfl' => 'filer_display#proc_display_view' #ダウンロード
  post 'secret_files/spin/dlfiles.sfl' => 'filer_display#proc_display_view' #ダウンロード

  # for mobile
  get 'secret_files_ipad/spin/domainsA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files_ipad/spin/file_listA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files_iphone/spin/domainsA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes
  get 'secret_files_iphone/spin/file_listA.sfl' => 'filer_display#proc_display_view' # => domain name and attributes

  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # => Mining2Analysis handler
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  get 'm2a_login/login.php'  => 'spin_m2a_login#proc_login'
  get 'm2a_login/login.centos6'  => 'spin_m2a_login#proc_login'
  get 'm2a_login/auth.html'  => 'spin_m2a_login#proc_m2a_login_view'
  get 'm2a_login'  => 'spin_m2a_login#proc_m2a_login_view'
  # true pivot part
  get 'tp/php/query.php' => 'm2a#tp_php'
  # schema workbech part
  get 'swb/php/query.php' => 'm2a#swb_php'
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  root 'home#index'
  get '/search', to: 'search#index'
  # get '/apps', to: 'apps#index'

  resources :apps, only: :show

  # may not need it
  get 'ext/resources' => 'ext#resources'

  # root :to => 'blackhole#reject_proc'
  get '*path', to: 'application#render_404'

end
