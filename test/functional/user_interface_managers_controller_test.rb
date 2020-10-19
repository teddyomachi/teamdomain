require 'test_helper'

class UserInterfaceManagersControllerTest < ActionController::TestCase
  setup do
    @user_interface_manager = user_interface_managers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_interface_managers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user_interface_manager" do
    assert_difference('UserInterfaceManager.count') do
      post :create, user_interface_manager: { pane_domains_a: @user_interface_manager.pane_domains_a, pane_domains_b: @user_interface_manager.pane_domains_b, pane_file_list_a: @user_interface_manager.pane_file_list_a, pane_file_list_b: @user_interface_manager.pane_file_list_b, pane_file_list_s: @user_interface_manager.pane_file_list_s, pane_folders_a: @user_interface_manager.pane_folders_a, pane_folders_at: @user_interface_manager.pane_folders_at, pane_folders_b: @user_interface_manager.pane_folders_b, pane_folders_bt: @user_interface_manager.pane_folders_bt, pane_group_list_created: @user_interface_manager.pane_group_list_created, pane_group_list_file: @user_interface_manager.pane_group_list_file, pane_group_list_folder: @user_interface_manager.pane_group_list_folder, pane_groupo_list_all: @user_interface_manager.pane_groupo_list_all, pane_mail_senders: @user_interface_manager.pane_mail_senders, pane_member_list_mygroup: @user_interface_manager.pane_member_list_mygroup, pane_recycler: @user_interface_manager.pane_recycler, pane_search_conditions: @user_interface_manager.pane_search_conditions, pane_search_option: @user_interface_manager.pane_search_option, pane_working_files: @user_interface_manager.pane_working_files }
    end

    assert_redirected_to user_interface_manager_path(assigns(:user_interface_manager))
  end

  test "should show user_interface_manager" do
    get :show, id: @user_interface_manager
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user_interface_manager
    assert_response :success
  end

  test "should update user_interface_manager" do
    put :update, id: @user_interface_manager, user_interface_manager: { pane_domains_a: @user_interface_manager.pane_domains_a, pane_domains_b: @user_interface_manager.pane_domains_b, pane_file_list_a: @user_interface_manager.pane_file_list_a, pane_file_list_b: @user_interface_manager.pane_file_list_b, pane_file_list_s: @user_interface_manager.pane_file_list_s, pane_folders_a: @user_interface_manager.pane_folders_a, pane_folders_at: @user_interface_manager.pane_folders_at, pane_folders_b: @user_interface_manager.pane_folders_b, pane_folders_bt: @user_interface_manager.pane_folders_bt, pane_group_list_created: @user_interface_manager.pane_group_list_created, pane_group_list_file: @user_interface_manager.pane_group_list_file, pane_group_list_folder: @user_interface_manager.pane_group_list_folder, pane_groupo_list_all: @user_interface_manager.pane_groupo_list_all, pane_mail_senders: @user_interface_manager.pane_mail_senders, pane_member_list_mygroup: @user_interface_manager.pane_member_list_mygroup, pane_recycler: @user_interface_manager.pane_recycler, pane_search_conditions: @user_interface_manager.pane_search_conditions, pane_search_option: @user_interface_manager.pane_search_option, pane_working_files: @user_interface_manager.pane_working_files }
    assert_redirected_to user_interface_manager_path(assigns(:user_interface_manager))
  end

  test "should destroy user_interface_manager" do
    assert_difference('UserInterfaceManager.count', -1) do
      delete :destroy, id: @user_interface_manager
    end

    assert_redirected_to user_interface_managers_path
  end
end
