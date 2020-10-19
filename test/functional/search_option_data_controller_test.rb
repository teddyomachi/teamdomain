require 'test_helper'

class SearchOptionDataControllerTest < ActionController::TestCase
  setup do
    @search_option_datum = search_option_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:search_option_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create search_option_datum" do
    assert_difference('SearchOptionDatum.count') do
      post :create, search_option_datum: { field_name: @search_option_datum.field_name, option_name: @search_option_datum.option_name, session_id: @search_option_datum.session_id, value: @search_option_datum.value }
    end

    assert_redirected_to search_option_datum_path(assigns(:search_option_datum))
  end

  test "should show search_option_datum" do
    get :show, id: @search_option_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @search_option_datum
    assert_response :success
  end

  test "should update search_option_datum" do
    put :update, id: @search_option_datum, search_option_datum: { field_name: @search_option_datum.field_name, option_name: @search_option_datum.option_name, session_id: @search_option_datum.session_id, value: @search_option_datum.value }
    assert_redirected_to search_option_datum_path(assigns(:search_option_datum))
  end

  test "should destroy search_option_datum" do
    assert_difference('SearchOptionDatum.count', -1) do
      delete :destroy, id: @search_option_datum
    end

    assert_redirected_to search_option_data_path
  end
end
