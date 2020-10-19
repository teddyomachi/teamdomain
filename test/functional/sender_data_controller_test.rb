require 'test_helper'

class SenderDataControllerTest < ActionController::TestCase
  setup do
    @sender_datum = sender_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sender_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sender_datum" do
    assert_difference('SenderDatum.count') do
      post :create, sender_datum: { memeber_id: @sender_datum.memeber_id, sender_email: @sender_datum.sender_email, sender_id: @sender_datum.sender_id, sender_name: @sender_datum.sender_name, session_id: @sender_datum.session_id }
    end

    assert_redirected_to sender_datum_path(assigns(:sender_datum))
  end

  test "should show sender_datum" do
    get :show, id: @sender_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sender_datum
    assert_response :success
  end

  test "should update sender_datum" do
    put :update, id: @sender_datum, sender_datum: { memeber_id: @sender_datum.memeber_id, sender_email: @sender_datum.sender_email, sender_id: @sender_datum.sender_id, sender_name: @sender_datum.sender_name, session_id: @sender_datum.session_id }
    assert_redirected_to sender_datum_path(assigns(:sender_datum))
  end

  test "should destroy sender_datum" do
    assert_difference('SenderDatum.count', -1) do
      delete :destroy, id: @sender_datum
    end

    assert_redirected_to sender_data_path
  end
end
