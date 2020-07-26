require 'test_helper'

class MemberDataControllerTest < ActionController::TestCase
  setup do
    @member_datum = member_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:member_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create member_datum" do
    assert_difference('MemberDatum.count') do
      post :create, member_datum: { hash_key: @member_datum.hash_key, member_description: @member_datum.member_description, member_id: @member_datum.member_id, member_name: @member_datum.member_name, member_remark: @member_datum.member_remark, session_id: @member_datum.session_id }
    end

    assert_redirected_to member_datum_path(assigns(:member_datum))
  end

  test "should show member_datum" do
    get :show, id: @member_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @member_datum
    assert_response :success
  end

  test "should update member_datum" do
    put :update, id: @member_datum, member_datum: { hash_key: @member_datum.hash_key, member_description: @member_datum.member_description, member_id: @member_datum.member_id, member_name: @member_datum.member_name, member_remark: @member_datum.member_remark, session_id: @member_datum.session_id }
    assert_redirected_to member_datum_path(assigns(:member_datum))
  end

  test "should destroy member_datum" do
    assert_difference('MemberDatum.count', -1) do
      delete :destroy, id: @member_datum
    end

    assert_redirected_to member_data_path
  end
end
