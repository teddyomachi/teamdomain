require 'test_helper'

class OperatorDataControllerTest < ActionController::TestCase
  setup do
    @operator_datum = operator_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:operator_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create operator_datum" do
    assert_difference('OperatorDatum.count') do
      post :create, operator_datum: { active_operator_id: @operator_datum.active_operator_id, active_operator_name: @operator_datum.active_operator_name, last_session_id: @operator_datum.last_session_id, operator_group_editable: @operator_datum.operator_group_editable, session_id: @operator_datum.session_id, session_id: @operator_datum.session_id }
    end

    assert_redirected_to operator_datum_path(assigns(:operator_datum))
  end

  test "should show operator_datum" do
    get :show, id: @operator_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @operator_datum
    assert_response :success
  end

  test "should update operator_datum" do
    put :update, id: @operator_datum, operator_datum: { active_operator_id: @operator_datum.active_operator_id, active_operator_name: @operator_datum.active_operator_name, last_session_id: @operator_datum.last_session_id, operator_group_editable: @operator_datum.operator_group_editable, session_id: @operator_datum.session_id, session_id: @operator_datum.session_id }
    assert_redirected_to operator_datum_path(assigns(:operator_datum))
  end

  test "should destroy operator_datum" do
    assert_difference('OperatorDatum.count', -1) do
      delete :destroy, id: @operator_datum
    end

    assert_redirected_to operator_data_path
  end
end
