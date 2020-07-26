require 'test_helper'

class DomainDataControllerTest < ActionController::TestCase
  setup do
    @domain_datum = domain_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:domain_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create domain_datum" do
    assert_difference('DomainDatum.count') do
      post :create, domain_datum: { cont_location: @domain_datum.cont_location, domain_link: @domain_datum.domain_link, domain_name: @domain_datum.domain_name, domain_writable_status: @domain_datum.domain_writable_status, hash_key: @domain_datum.hash_key, img: @domain_datum.img, session_id: @domain_datum.session_id }
    end

    assert_redirected_to domain_datum_path(assigns(:domain_datum))
  end

  test "should show domain_datum" do
    get :show, id: @domain_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @domain_datum
    assert_response :success
  end

  test "should update domain_datum" do
    put :update, id: @domain_datum, domain_datum: { cont_location: @domain_datum.cont_location, domain_link: @domain_datum.domain_link, domain_name: @domain_datum.domain_name, domain_writable_status: @domain_datum.domain_writable_status, hash_key: @domain_datum.hash_key, img: @domain_datum.img, session_id: @domain_datum.session_id }
    assert_redirected_to domain_datum_path(assigns(:domain_datum))
  end

  test "should destroy domain_datum" do
    assert_difference('DomainDatum.count', -1) do
      delete :destroy, id: @domain_datum
    end

    assert_redirected_to domain_data_path
  end
end
