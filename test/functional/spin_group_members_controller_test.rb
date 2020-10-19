require 'test_helper'

class SpinGroupMembersControllerTest < ActionController::TestCase
  setup do
    @spin_group_member = spin_group_members(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_group_members)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_group_member" do
    assert_difference('SpinGroupMember.count') do
      post :create, spin_group_member: { spin_gid: @spin_group_member.spin_gid, spin_uid: @spin_group_member.spin_uid }
    end

    assert_redirected_to spin_group_member_path(assigns(:spin_group_member))
  end

  test "should show spin_group_member" do
    get :show, id: @spin_group_member
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_group_member
    assert_response :success
  end

  test "should update spin_group_member" do
    put :update, id: @spin_group_member, spin_group_member: { spin_gid: @spin_group_member.spin_gid, spin_uid: @spin_group_member.spin_uid }
    assert_redirected_to spin_group_member_path(assigns(:spin_group_member))
  end

  test "should destroy spin_group_member" do
    assert_difference('SpinGroupMember.count', -1) do
      delete :destroy, id: @spin_group_member
    end

    assert_redirected_to spin_group_members_path
  end
end
