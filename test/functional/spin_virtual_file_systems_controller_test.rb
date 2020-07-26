require 'test_helper'

class SpinVirtualFileSystemsControllerTest < ActionController::TestCase
  setup do
    @spin_virtual_file_system = spin_virtual_file_systems(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_virtual_file_systems)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_virtual_file_system" do
    assert_difference('SpinVirtualFileSystem.count') do
      post :create, spin_virtual_file_system: { spin_vfs_access_mode: @spin_virtual_file_system.spin_vfs_access_mode, spin_vfs_attibutes: @spin_virtual_file_system.spin_vfs_attibutes, spin_vfs_name: @spin_virtual_file_system.spin_vfs_name, spin_vfs_type: @spin_virtual_file_system.spin_vfs_type }
    end

    assert_redirected_to spin_virtual_file_system_path(assigns(:spin_virtual_file_system))
  end

  test "should show spin_virtual_file_system" do
    get :show, id: @spin_virtual_file_system
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_virtual_file_system
    assert_response :success
  end

  test "should update spin_virtual_file_system" do
    put :update, id: @spin_virtual_file_system, spin_virtual_file_system: { spin_vfs_access_mode: @spin_virtual_file_system.spin_vfs_access_mode, spin_vfs_attibutes: @spin_virtual_file_system.spin_vfs_attibutes, spin_vfs_name: @spin_virtual_file_system.spin_vfs_name, spin_vfs_type: @spin_virtual_file_system.spin_vfs_type }
    assert_redirected_to spin_virtual_file_system_path(assigns(:spin_virtual_file_system))
  end

  test "should destroy spin_virtual_file_system" do
    assert_difference('SpinVirtualFileSystem.count', -1) do
      delete :destroy, id: @spin_virtual_file_system
    end

    assert_redirected_to spin_virtual_file_systems_path
  end
end
