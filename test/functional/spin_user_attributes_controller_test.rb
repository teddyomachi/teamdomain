require 'test_helper'

class SpinUserAttributesControllerTest < ActionController::TestCase
  setup do
    @spin_user_attribute = spin_user_attributes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_user_attributes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_user_attribute" do
    assert_difference('SpinUserAttribute.count') do
      post :create, spin_user_attribute: { mail_addr2: @spin_user_attribute.mail_addr2, mail_addr: @spin_user_attribute.mail_addr, organization1: @spin_user_attribute.organization1, organization2: @spin_user_attribute.organization2, organization3: @spin_user_attribute.organization3, organization4: @spin_user_attribute.organization4, organization5: @spin_user_attribute.organization5, organization6: @spin_user_attribute.organization6, organization7: @spin_user_attribute.organization7, organization8: @spin_user_attribute.organization8, real_uname1: @spin_user_attribute.real_uname1, real_uname2: @spin_user_attribute.real_uname2, real_unameM: @spin_user_attribute.real_unameM, spin_uid: @spin_user_attribute.spin_uid, spin_uname: @spin_user_attribute.spin_uname, tel_area_code_1: @spin_user_attribute.tel_area_code_1, tel_country_code_1: @spin_user_attribute.tel_country_code_1, tel_ext_1: @spin_user_attribute.tel_ext_1, tel_number_1: @spin_user_attribute.tel_number_1, tel_pid_code_1: @spin_user_attribute.tel_pid_code_1, user_attributes: @spin_user_attribute.user_attributes }
    end

    assert_redirected_to spin_user_attribute_path(assigns(:spin_user_attribute))
  end

  test "should show spin_user_attribute" do
    get :show, id: @spin_user_attribute
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_user_attribute
    assert_response :success
  end

  test "should update spin_user_attribute" do
    put :update, id: @spin_user_attribute, spin_user_attribute: { mail_addr2: @spin_user_attribute.mail_addr2, mail_addr: @spin_user_attribute.mail_addr, organization1: @spin_user_attribute.organization1, organization2: @spin_user_attribute.organization2, organization3: @spin_user_attribute.organization3, organization4: @spin_user_attribute.organization4, organization5: @spin_user_attribute.organization5, organization6: @spin_user_attribute.organization6, organization7: @spin_user_attribute.organization7, organization8: @spin_user_attribute.organization8, real_uname1: @spin_user_attribute.real_uname1, real_uname2: @spin_user_attribute.real_uname2, real_unameM: @spin_user_attribute.real_unameM, spin_uid: @spin_user_attribute.spin_uid, spin_uname: @spin_user_attribute.spin_uname, tel_area_code_1: @spin_user_attribute.tel_area_code_1, tel_country_code_1: @spin_user_attribute.tel_country_code_1, tel_ext_1: @spin_user_attribute.tel_ext_1, tel_number_1: @spin_user_attribute.tel_number_1, tel_pid_code_1: @spin_user_attribute.tel_pid_code_1, user_attributes: @spin_user_attribute.user_attributes }
    assert_redirected_to spin_user_attribute_path(assigns(:spin_user_attribute))
  end

  test "should destroy spin_user_attribute" do
    assert_difference('SpinUserAttribute.count', -1) do
      delete :destroy, id: @spin_user_attribute
    end

    assert_redirected_to spin_user_attributes_path
  end
end
