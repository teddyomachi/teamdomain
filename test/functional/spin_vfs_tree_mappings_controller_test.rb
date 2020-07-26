require 'test_helper'

class SpinVfsTreeMappingsControllerTest < ActionController::TestCase
  setup do
    @spin_vfs_tree_mapping = spin_vfs_tree_mappings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_vfs_tree_mappings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_vfs_tree_mapping" do
    assert_difference('SpinVfsTreeMapping.count') do
      post :create, spin_vfs_tree_mapping: { spin_node_tree: @spin_vfs_tree_mapping.spin_node_tree, spin_vfs: @spin_vfs_tree_mapping.spin_vfs }
    end

    assert_redirected_to spin_vfs_tree_mapping_path(assigns(:spin_vfs_tree_mapping))
  end

  test "should show spin_vfs_tree_mapping" do
    get :show, id: @spin_vfs_tree_mapping
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_vfs_tree_mapping
    assert_response :success
  end

  test "should update spin_vfs_tree_mapping" do
    put :update, id: @spin_vfs_tree_mapping, spin_vfs_tree_mapping: { spin_node_tree: @spin_vfs_tree_mapping.spin_node_tree, spin_vfs: @spin_vfs_tree_mapping.spin_vfs }
    assert_redirected_to spin_vfs_tree_mapping_path(assigns(:spin_vfs_tree_mapping))
  end

  test "should destroy spin_vfs_tree_mapping" do
    assert_difference('SpinVfsTreeMapping.count', -1) do
      delete :destroy, id: @spin_vfs_tree_mapping
    end

    assert_redirected_to spin_vfs_tree_mappings_path
  end
end
