require 'test_helper'

class SpinUsersControllerTest < ActionController::TestCase
  setup do
    @spin_user = spin_users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_user" do
    assert_difference('SpinUser.count') do
      post :create, spin_user: { spin_gid: @spin_user.spin_gid, spin_passwd: @spin_user.spin_passwd, spin_projid: @spin_user.spin_projid, spin_uid: @spin_user.spin_uid, spin_uname: @spin_user.spin_uname, user_level_x: @spin_user.user_level_x, user_level_y: @spin_user.user_level_y }
    end

    assert_redirected_to spin_user_path(assigns(:spin_user))
  end

  test "should show spin_user" do
    get :show, id: @spin_user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_user
    assert_response :success
  end

  test "should update spin_user" do
    put :update, id: @spin_user, spin_user: { spin_gid: @spin_user.spin_gid, spin_passwd: @spin_user.spin_passwd, spin_projid: @spin_user.spin_projid, spin_uid: @spin_user.spin_uid, spin_uname: @spin_user.spin_uname, user_level_x: @spin_user.user_level_x, user_level_y: @spin_user.user_level_y }
    assert_redirected_to spin_user_path(assigns(:spin_user))
  end

  test "should destroy spin_user" do
    assert_difference('SpinUser.count', -1) do
      delete :destroy, id: @spin_user
    end

    assert_redirected_to spin_users_path
  end
end
