require 'test_helper'

class SpinStoragesControllerTest < ActionController::TestCase
  setup do
    @spin_storage = spin_storages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_storages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_storage" do
    assert_difference('SpinStorage.count') do
      post :create, spin_storage: { mapping_logic: @spin_storage.mapping_logic, storage_attributes: @spin_storage.storage_attributes, storage_max_size: @spin_storage.storage_max_size, storage_root: @spin_storage.storage_root, storage_server: @spin_storage.storage_server }
    end

    assert_redirected_to spin_storage_path(assigns(:spin_storage))
  end

  test "should show spin_storage" do
    get :show, id: @spin_storage
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_storage
    assert_response :success
  end

  test "should update spin_storage" do
    put :update, id: @spin_storage, spin_storage: { mapping_logic: @spin_storage.mapping_logic, storage_attributes: @spin_storage.storage_attributes, storage_max_size: @spin_storage.storage_max_size, storage_root: @spin_storage.storage_root, storage_server: @spin_storage.storage_server }
    assert_redirected_to spin_storage_path(assigns(:spin_storage))
  end

  test "should destroy spin_storage" do
    assert_difference('SpinStorage.count', -1) do
      delete :destroy, id: @spin_storage
    end

    assert_redirected_to spin_storages_path
  end
end
