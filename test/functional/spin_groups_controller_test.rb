require 'test_helper'

class SpinGroupsControllerTest < ActionController::TestCase
  setup do
    @spin_group = spin_groups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_group" do
    assert_difference('SpinGroup.count') do
      post :create, spin_group: { group_atrtributes: @spin_group.group_atrtributes, group_descr: @spin_group.group_descr, spin_gid: @spin_group.spin_gid, spin_group_name: @spin_group.spin_group_name }
    end

    assert_redirected_to spin_group_path(assigns(:spin_group))
  end

  test "should show spin_group" do
    get :show, id: @spin_group
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_group
    assert_response :success
  end

  test "should update spin_group" do
    put :update, id: @spin_group, spin_group: { group_atrtributes: @spin_group.group_atrtributes, group_descr: @spin_group.group_descr, spin_gid: @spin_group.spin_gid, spin_group_name: @spin_group.spin_group_name }
    assert_redirected_to spin_group_path(assigns(:spin_group))
  end

  test "should destroy spin_group" do
    assert_difference('SpinGroup.count', -1) do
      delete :destroy, id: @spin_group
    end

    assert_redirected_to spin_groups_path
  end
end
