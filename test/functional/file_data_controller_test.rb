require 'test_helper'

class FileDataControllerTest < ActionController::TestCase
  setup do
    @file_datum = file_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:file_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create file_datum" do
    assert_difference('FileDatum.count') do
      post :create, file_datum: { access_group: @file_datum.access_group, client: @file_datum.client, cont_location: @file_datum.cont_location, control_right: @file_datum.control_right, copyright: @file_datum.copyright, created_date: @file_datum.created_date, creator: @file_datum.creator, description: @file_datum.description, details: @file_datum.details, dirty: @file_datum.dirty, duration: @file_datum.duration, file_exact_size: @file_datum.file_exact_size, file_name: @file_datum.file_name, file_readable_status: @file_datum.file_readable_status, file_size: @file_datum.file_size, file_type: @file_datum.file_type, file_version: @file_datum.file_version, file_writable_status: @file_datum.file_writable_status, folder_hash_key: @file_datum.folder_hash_key, folder_readable_status: @file_datum.folder_readable_status, folder_writable_status: @file_datum.folder_writable_status, frame_size: @file_datum.frame_size, hash_key: @file_datum.hash_key, icon_image: @file_datum.icon_image, id_lc_by: @file_datum.id_lc_by, keyword: @file_datum.keyword, location: @file_datum.location, lock: @file_datum.lock, modified_date: @file_datum.modified_date, modifier: @file_datum.modifier, name_lc_by: @file_datum.name_lc_by, open_status: @file_datum.open_status, owner: @file_datum.owner, ownership: @file_datum.ownership, portrait_right: @file_datum.portrait_right, produced_date: @file_datum.produced_date, producer: @file_datum.producer, session_id: @file_datum.session_id, subtitle: @file_datum.subtitle, thumbnail_image: @file_datum.thumbnail_image, title: @file_datum.title, url: @file_datum.url }
    end

    assert_redirected_to file_datum_path(assigns(:file_datum))
  end

  test "should show file_datum" do
    get :show, id: @file_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @file_datum
    assert_response :success
  end

  test "should update file_datum" do
    put :update, id: @file_datum, file_datum: { access_group: @file_datum.access_group, client: @file_datum.client, cont_location: @file_datum.cont_location, control_right: @file_datum.control_right, copyright: @file_datum.copyright, created_date: @file_datum.created_date, creator: @file_datum.creator, description: @file_datum.description, details: @file_datum.details, dirty: @file_datum.dirty, duration: @file_datum.duration, file_exact_size: @file_datum.file_exact_size, file_name: @file_datum.file_name, file_readable_status: @file_datum.file_readable_status, file_size: @file_datum.file_size, file_type: @file_datum.file_type, file_version: @file_datum.file_version, file_writable_status: @file_datum.file_writable_status, folder_hash_key: @file_datum.folder_hash_key, folder_readable_status: @file_datum.folder_readable_status, folder_writable_status: @file_datum.folder_writable_status, frame_size: @file_datum.frame_size, hash_key: @file_datum.hash_key, icon_image: @file_datum.icon_image, id_lc_by: @file_datum.id_lc_by, keyword: @file_datum.keyword, location: @file_datum.location, lock: @file_datum.lock, modified_date: @file_datum.modified_date, modifier: @file_datum.modifier, name_lc_by: @file_datum.name_lc_by, open_status: @file_datum.open_status, owner: @file_datum.owner, ownership: @file_datum.ownership, portrait_right: @file_datum.portrait_right, produced_date: @file_datum.produced_date, producer: @file_datum.producer, session_id: @file_datum.session_id, subtitle: @file_datum.subtitle, thumbnail_image: @file_datum.thumbnail_image, title: @file_datum.title, url: @file_datum.url }
    assert_redirected_to file_datum_path(assigns(:file_datum))
  end

  test "should destroy file_datum" do
    assert_difference('FileDatum.count', -1) do
      delete :destroy, id: @file_datum
    end

    assert_redirected_to file_data_path
  end
end
