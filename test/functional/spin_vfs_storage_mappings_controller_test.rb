require 'test_helper'

class SpinVfsStorageMappingsControllerTest < ActionController::TestCase
  setup do
    @spin_vfs_storage_mapping = spin_vfs_storage_mappings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_vfs_storage_mappings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_vfs_storage_mapping" do
    assert_difference('SpinVfsStorageMapping.count') do
      post :create, spin_vfs_storage_mapping: { spin_storage: @spin_vfs_storage_mapping.spin_storage, spin_vfs: @spin_vfs_storage_mapping.spin_vfs }
    end

    assert_redirected_to spin_vfs_storage_mapping_path(assigns(:spin_vfs_storage_mapping))
  end

  test "should show spin_vfs_storage_mapping" do
    get :show, id: @spin_vfs_storage_mapping
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_vfs_storage_mapping
    assert_response :success
  end

  test "should update spin_vfs_storage_mapping" do
    put :update, id: @spin_vfs_storage_mapping, spin_vfs_storage_mapping: { spin_storage: @spin_vfs_storage_mapping.spin_storage, spin_vfs: @spin_vfs_storage_mapping.spin_vfs }
    assert_redirected_to spin_vfs_storage_mapping_path(assigns(:spin_vfs_storage_mapping))
  end

  test "should destroy spin_vfs_storage_mapping" do
    assert_difference('SpinVfsStorageMapping.count', -1) do
      delete :destroy, id: @spin_vfs_storage_mapping
    end

    assert_redirected_to spin_vfs_storage_mappings_path
  end
end
