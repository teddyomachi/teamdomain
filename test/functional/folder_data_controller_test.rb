require 'test_helper'

class FolderDataControllerTest < ActionController::TestCase
  setup do
    @folder_datum = folder_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:folder_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create folder_datum" do
    assert_difference('FolderDatum.count') do
      post :create, folder_datum: { capacity: @folder_datum.capacity, children: @folder_datum.children, cls: @folder_datum.cls, cont_location: @folder_datum.cont_location, control_right: @folder_datum.control_right, created_date: @folder_datum.created_date, creator: @folder_datum.creator, expanded: @folder_datum.expanded, fileNumber: @folder_datum.fileNumber, folder_name: @folder_datum.folder_name, folder_readable_status: @folder_datum.folder_readable_status, folder_writable_status: @folder_datum.folder_writable_status, hash_key: @folder_datum.hash_key, id: @folder_datum.id, img: @folder_datum.img, leaf: @folder_datum.leaf, owner: @folder_datum.owner, ownership: @folder_datum.ownership, parent_readable_status: @folder_datum.parent_readable_status, parent_writable_status: @folder_datum.parent_writable_status, restSpace: @folder_datum.restSpace, session_id: @folder_datum.session_id, subFolders: @folder_datum.subFolders, text: @folder_datum.text, updated_date: @folder_datum.updated_date, updater: @folder_datum.updater, usedRate: @folder_datum.usedRate, usedSpace: @folder_datum.usedSpace, workingFolder: @folder_datum.workingFolder }
    end

    assert_redirected_to folder_datum_path(assigns(:folder_datum))
  end

  test "should show folder_datum" do
    get :show, id: @folder_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @folder_datum
    assert_response :success
  end

  test "should update folder_datum" do
    put :update, id: @folder_datum, folder_datum: { capacity: @folder_datum.capacity, children: @folder_datum.children, cls: @folder_datum.cls, cont_location: @folder_datum.cont_location, control_right: @folder_datum.control_right, created_date: @folder_datum.created_date, creator: @folder_datum.creator, expanded: @folder_datum.expanded, fileNumber: @folder_datum.fileNumber, folder_name: @folder_datum.folder_name, folder_readable_status: @folder_datum.folder_readable_status, folder_writable_status: @folder_datum.folder_writable_status, hash_key: @folder_datum.hash_key, id: @folder_datum.id, img: @folder_datum.img, leaf: @folder_datum.leaf, owner: @folder_datum.owner, ownership: @folder_datum.ownership, parent_readable_status: @folder_datum.parent_readable_status, parent_writable_status: @folder_datum.parent_writable_status, restSpace: @folder_datum.restSpace, session_id: @folder_datum.session_id, subFolders: @folder_datum.subFolders, text: @folder_datum.text, updated_date: @folder_datum.updated_date, updater: @folder_datum.updater, usedRate: @folder_datum.usedRate, usedSpace: @folder_datum.usedSpace, workingFolder: @folder_datum.workingFolder }
    assert_redirected_to folder_datum_path(assigns(:folder_datum))
  end

  test "should destroy folder_datum" do
    assert_difference('FolderDatum.count', -1) do
      delete :destroy, id: @folder_datum
    end

    assert_redirected_to folder_data_path
  end
end
