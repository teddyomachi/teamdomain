require 'test_helper'

class TargetFolderDataControllerTest < ActionController::TestCase
  setup do
    @target_folder_datum = target_folder_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:target_folder_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create target_folder_datum" do
    assert_difference('TargetFolderDatum.count') do
      post :create, target_folder_datum: { id: @target_folder_datum.id, session_id: @target_folder_datum.session_id, target_cont_location: @target_folder_datum.target_cont_location, target_folder: @target_folder_datum.target_folder, target_folder_readable_status: @target_folder_datum.target_folder_readable_status, target_folder_writable_status: @target_folder_datum.target_folder_writable_status, target_hash_key: @target_folder_datum.target_hash_key, target_ownership: @target_folder_datum.target_ownership, target_parent_readable_status: @target_folder_datum.target_parent_readable_status, target_parent_writable_status: @target_folder_datum.target_parent_writable_status, text: @target_folder_datum.text }
    end

    assert_redirected_to target_folder_datum_path(assigns(:target_folder_datum))
  end

  test "should show target_folder_datum" do
    get :show, id: @target_folder_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @target_folder_datum
    assert_response :success
  end

  test "should update target_folder_datum" do
    put :update, id: @target_folder_datum, target_folder_datum: { id: @target_folder_datum.id, session_id: @target_folder_datum.session_id, target_cont_location: @target_folder_datum.target_cont_location, target_folder: @target_folder_datum.target_folder, target_folder_readable_status: @target_folder_datum.target_folder_readable_status, target_folder_writable_status: @target_folder_datum.target_folder_writable_status, target_hash_key: @target_folder_datum.target_hash_key, target_ownership: @target_folder_datum.target_ownership, target_parent_readable_status: @target_folder_datum.target_parent_readable_status, target_parent_writable_status: @target_folder_datum.target_parent_writable_status, text: @target_folder_datum.text }
    assert_redirected_to target_folder_datum_path(assigns(:target_folder_datum))
  end

  test "should destroy target_folder_datum" do
    assert_difference('TargetFolderDatum.count', -1) do
      delete :destroy, id: @target_folder_datum
    end

    assert_redirected_to target_folder_data_path
  end
end
