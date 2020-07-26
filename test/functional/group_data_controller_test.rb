require 'test_helper'

class GroupDataControllerTest < ActionController::TestCase
  setup do
    @group_datum = group_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:group_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create group_datum" do
    assert_difference('GroupDatum.count') do
      post :create, group_datum: { editable_status: @group_datum.editable_status, group_description: @group_datum.group_description, group_name: @group_datum.group_name, group_privilege: @group_datum.group_privilege, hash_key: @group_datum.hash_key, id: @group_datum.id, member_description: @group_datum.member_description, member_id: @group_datum.member_id, member_name: @group_datum.member_name, session_id: @group_datum.session_id, target_hash_key: @group_datum.target_hash_key }
    end

    assert_redirected_to group_datum_path(assigns(:group_datum))
  end

  test "should show group_datum" do
    get :show, id: @group_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @group_datum
    assert_response :success
  end

  test "should update group_datum" do
    put :update, id: @group_datum, group_datum: { editable_status: @group_datum.editable_status, group_description: @group_datum.group_description, group_name: @group_datum.group_name, group_privilege: @group_datum.group_privilege, hash_key: @group_datum.hash_key, id: @group_datum.id, member_description: @group_datum.member_description, member_id: @group_datum.member_id, member_name: @group_datum.member_name, session_id: @group_datum.session_id, target_hash_key: @group_datum.target_hash_key }
    assert_redirected_to group_datum_path(assigns(:group_datum))
  end

  test "should destroy group_datum" do
    assert_difference('GroupDatum.count', -1) do
      delete :destroy, id: @group_datum
    end

    assert_redirected_to group_data_path
  end
end
