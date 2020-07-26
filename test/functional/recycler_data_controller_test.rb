require 'test_helper'

class RecyclerDataControllerTest < ActionController::TestCase
  setup do
    @recycler_datum = recycler_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:recycler_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create recycler_datum" do
    assert_difference('RecyclerDatum.count') do
      post :create, recycler_datum: { cont_location: @recycler_datum.cont_location, file_exact_size: @recycler_datum.file_exact_size, file_name: @recycler_datum.file_name, file_type: @recycler_datum.file_type, hash_key: @recycler_datum.hash_key, session_id: @recycler_datum.session_id, url: @recycler_datum.url }
    end

    assert_redirected_to recycler_datum_path(assigns(:recycler_datum))
  end

  test "should show recycler_datum" do
    get :show, id: @recycler_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @recycler_datum
    assert_response :success
  end

  test "should update recycler_datum" do
    put :update, id: @recycler_datum, recycler_datum: { cont_location: @recycler_datum.cont_location, file_exact_size: @recycler_datum.file_exact_size, file_name: @recycler_datum.file_name, file_type: @recycler_datum.file_type, hash_key: @recycler_datum.hash_key, session_id: @recycler_datum.session_id, url: @recycler_datum.url }
    assert_redirected_to recycler_datum_path(assigns(:recycler_datum))
  end

  test "should destroy recycler_datum" do
    assert_difference('RecyclerDatum.count', -1) do
      delete :destroy, id: @recycler_datum
    end

    assert_redirected_to recycler_data_path
  end
end
