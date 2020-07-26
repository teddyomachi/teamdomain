require 'test_helper'

class SpinSessionsControllerTest < ActionController::TestCase
  setup do
    @spin_session = spin_sessions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_sessions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_session" do
    assert_difference('SpinSession.count') do
      post :create, spin_session: { session_expire: @spin_session.session_expire, session_status: @spin_session.session_status, spin_domaindata_A_id: @spin_session.spin_domaindata_A_id, spin_domaindata_B_id: @spin_session.spin_domaindata_B_id, spin_filedata_id: @spin_session.spin_filedata_id, spin_folder_data_B_id: @spin_session.spin_folder_data_B_id, spin_folderdata_A_id: @spin_session.spin_folderdata_A_id, spin_groupdata_id: @spin_session.spin_groupdata_id, spin_last_login: @spin_session.spin_last_login, spin_last_logout: @spin_session.spin_last_logout, spin_login_time: @spin_session.spin_login_time, spin_memberdata_id: @spin_session.spin_memberdata_id, spin_operatordata_id: @spin_session.spin_operatordata_id, spin_recycledata_id: @spin_session.spin_recycledata_id, spin_search_condition_id: @spin_session.spin_search_condition_id, spin_search_option_id: @spin_session.spin_search_option_id, spin_senderdata_id: @spin_session.spin_senderdata_id, spin_session: @spin_session.spin_session, spin_session_data: @spin_session.spin_session_data, spin_uid: @spin_session.spin_uid, spin_uname: @spin_session.spin_uname }
    end

    assert_redirected_to spin_session_path(assigns(:spin_session))
  end

  test "should show spin_session" do
    get :show, id: @spin_session
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_session
    assert_response :success
  end

  test "should update spin_session" do
    put :update, id: @spin_session, spin_session: { session_expire: @spin_session.session_expire, session_status: @spin_session.session_status, spin_domaindata_A_id: @spin_session.spin_domaindata_A_id, spin_domaindata_B_id: @spin_session.spin_domaindata_B_id, spin_filedata_id: @spin_session.spin_filedata_id, spin_folder_data_B_id: @spin_session.spin_folder_data_B_id, spin_folderdata_A_id: @spin_session.spin_folderdata_A_id, spin_groupdata_id: @spin_session.spin_groupdata_id, spin_last_login: @spin_session.spin_last_login, spin_last_logout: @spin_session.spin_last_logout, spin_login_time: @spin_session.spin_login_time, spin_memberdata_id: @spin_session.spin_memberdata_id, spin_operatordata_id: @spin_session.spin_operatordata_id, spin_recycledata_id: @spin_session.spin_recycledata_id, spin_search_condition_id: @spin_session.spin_search_condition_id, spin_search_option_id: @spin_session.spin_search_option_id, spin_senderdata_id: @spin_session.spin_senderdata_id, spin_session: @spin_session.spin_session, spin_session_data: @spin_session.spin_session_data, spin_uid: @spin_session.spin_uid, spin_uname: @spin_session.spin_uname }
    assert_redirected_to spin_session_path(assigns(:spin_session))
  end

  test "should destroy spin_session" do
    assert_difference('SpinSession.count', -1) do
      delete :destroy, id: @spin_session
    end

    assert_redirected_to spin_sessions_path
  end
end
