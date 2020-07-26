require 'test_helper'

class SpinObjectsControllerTest < ActionController::TestCase
  setup do
    @spin_object = spin_objects(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_objects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_object" do
    assert_difference('SpinObject.count') do
      post :create, spin_object: { date_created: @spin_object.date_created, date_modified: @spin_object.date_modified, node_type: @spin_object.node_type, node_version: @spin_object.node_version, node_x_coord: @spin_object.node_x_coord, node_x_pr_coord: @spin_object.node_x_pr_coord, node_y_coord: @spin_object.node_y_coord, object_attributes: @spin_object.object_attributes, object_name: @spin_object.object_name, src_attributes: @spin_object.src_attributes, src_platform: @spin_object.src_platform }
    end

    assert_redirected_to spin_object_path(assigns(:spin_object))
  end

  test "should show spin_object" do
    get :show, id: @spin_object
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_object
    assert_response :success
  end

  test "should update spin_object" do
    put :update, id: @spin_object, spin_object: { date_created: @spin_object.date_created, date_modified: @spin_object.date_modified, node_type: @spin_object.node_type, node_version: @spin_object.node_version, node_x_coord: @spin_object.node_x_coord, node_x_pr_coord: @spin_object.node_x_pr_coord, node_y_coord: @spin_object.node_y_coord, object_attributes: @spin_object.object_attributes, object_name: @spin_object.object_name, src_attributes: @spin_object.src_attributes, src_platform: @spin_object.src_platform }
    assert_redirected_to spin_object_path(assigns(:spin_object))
  end

  test "should destroy spin_object" do
    assert_difference('SpinObject.count', -1) do
      delete :destroy, id: @spin_object
    end

    assert_redirected_to spin_objects_path
  end
end
