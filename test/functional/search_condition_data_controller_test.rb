require 'test_helper'

class SearchConditionDataControllerTest < ActionController::TestCase
  setup do
    @search_condition_datum = search_condition_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:search_condition_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create search_condition_datum" do
    assert_difference('SearchConditionDatum.count') do
      post :create, search_condition_datum: { session_id: @search_condition_datum.session_id, target_checked_out_by_me: @search_condition_datum.target_checked_out_by_me, target_created_by_me: @search_condition_datum.target_created_by_me, target_created_date_begin: @search_condition_datum.target_created_date_begin, target_created_date_end: @search_condition_datum.target_created_date_end, target_creator: @search_condition_datum.target_creator, target_file_name: @search_condition_datum.target_file_name, target_file_size_max: @search_condition_datum.target_file_size_max, target_file_size_min: @search_condition_datum.target_file_size_min, target_folder: @search_condition_datum.target_folder, target_locked_by_me: @search_condition_datum.target_locked_by_me, target_max_display_files: @search_condition_datum.target_max_display_files, target_modified_by_me: @search_condition_datum.target_modified_by_me, target_modified_date_begin: @search_condition_datum.target_modified_date_begin, target_modified_date_end: @search_condition_datum.target_modified_date_end, target_modifier: @search_condition_datum.target_modifier, target_subfolder: @search_condition_datum.target_subfolder }
    end

    assert_redirected_to search_condition_datum_path(assigns(:search_condition_datum))
  end

  test "should show search_condition_datum" do
    get :show, id: @search_condition_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @search_condition_datum
    assert_response :success
  end

  test "should update search_condition_datum" do
    put :update, id: @search_condition_datum, search_condition_datum: { session_id: @search_condition_datum.session_id, target_checked_out_by_me: @search_condition_datum.target_checked_out_by_me, target_created_by_me: @search_condition_datum.target_created_by_me, target_created_date_begin: @search_condition_datum.target_created_date_begin, target_created_date_end: @search_condition_datum.target_created_date_end, target_creator: @search_condition_datum.target_creator, target_file_name: @search_condition_datum.target_file_name, target_file_size_max: @search_condition_datum.target_file_size_max, target_file_size_min: @search_condition_datum.target_file_size_min, target_folder: @search_condition_datum.target_folder, target_locked_by_me: @search_condition_datum.target_locked_by_me, target_max_display_files: @search_condition_datum.target_max_display_files, target_modified_by_me: @search_condition_datum.target_modified_by_me, target_modified_date_begin: @search_condition_datum.target_modified_date_begin, target_modified_date_end: @search_condition_datum.target_modified_date_end, target_modifier: @search_condition_datum.target_modifier, target_subfolder: @search_condition_datum.target_subfolder }
    assert_redirected_to search_condition_datum_path(assigns(:search_condition_datum))
  end

  test "should destroy search_condition_datum" do
    assert_difference('SearchConditionDatum.count', -1) do
      delete :destroy, id: @search_condition_datum
    end

    assert_redirected_to search_condition_data_path
  end
end
