require 'test_helper'

class SpinDomainsControllerTest < ActionController::TestCase
  setup do
    @spin_domain = spin_domains(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spin_domains)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spin_domain" do
    assert_difference('SpinDomain.count') do
      post :create, spin_domain: { domain_atrtributes: @spin_domain.domain_atrtributes, domain_descr: @spin_domain.domain_descr, spin_did: @spin_domain.spin_did, spin_domain_name: @spin_domain.spin_domain_name, spin_domain_root: @spin_domain.spin_domain_root }
    end

    assert_redirected_to spin_domain_path(assigns(:spin_domain))
  end

  test "should show spin_domain" do
    get :show, id: @spin_domain
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spin_domain
    assert_response :success
  end

  test "should update spin_domain" do
    put :update, id: @spin_domain, spin_domain: { domain_atrtributes: @spin_domain.domain_atrtributes, domain_descr: @spin_domain.domain_descr, spin_did: @spin_domain.spin_did, spin_domain_name: @spin_domain.spin_domain_name, spin_domain_root: @spin_domain.spin_domain_root }
    assert_redirected_to spin_domain_path(assigns(:spin_domain))
  end

  test "should destroy spin_domain" do
    assert_difference('SpinDomain.count', -1) do
      delete :destroy, id: @spin_domain
    end

    assert_redirected_to spin_domains_path
  end
end
