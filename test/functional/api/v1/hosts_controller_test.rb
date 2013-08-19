require 'test_helper'

class Api::V1::HostsControllerTest < ActionController::TestCase

  def valid_attrs
    { :name               => 'testhost11',
      :environment_id     => environments(:production).id,
      :domain_id          => domains(:mydomain).id,
      :ip                 => '10.0.0.20',
      :mac                => '52:53:00:1e:85:93',
      :architecture_id    => Architecture.find_by_name('x86_64').id,
      :operatingsystem_id => Operatingsystem.find_by_name('Redhat').id,
      :puppet_proxy_id    => smart_proxies(:one).id
    }
  end

  test "should get index" do
    get :index, { }
    assert_response :success
    assert_not_nil assigns(:hosts)
    hosts = ActiveSupport::JSON.decode(@response.body)
    assert !hosts.empty?
  end

  test "should show individual record" do
    get :show, { :id => hosts(:one).to_param }
    assert_response :success
    show_response = ActiveSupport::JSON.decode(@response.body)
    assert !show_response.empty?
  end

  test "should create host" do
    disable_orchestration
    assert_difference('Host.count') do
      post :create, { :host => valid_attrs }
    end
    assert_response :success
    last_host = Host.order('id desc').last
  end

  test "should create host with managed is false if parameter is passed" do
    disable_orchestration
    post :create, { :host => valid_attrs.merge!(:managed => false) }
    assert_response :success
    last_host = Host.order('id desc').last
    assert_equal false, last_host.managed?
  end

  test "should update host" do
    put :update, { :id => hosts(:two).to_param, :host => { } }
    assert_response :success
  end

  test "should destroy hosts" do
    assert_difference('Host.count', -1) do
      delete :destroy, { :id => hosts(:one).to_param }
    end
    assert_response :success
  end

  test "should show status hosts" do
    get :status, { :id => hosts(:one).to_param }
    assert_response :success
  end

  test "should be able to create hosts even when restricted" do
    disable_orchestration
    assert_difference('Host.count') do
      post :create, { :host => valid_attrs }
    end
    assert_response :success
  end

  test "should allow access to restricted user who owns the host" do
    as_user :restricted do
      get :show, { :id => hosts(:owned_by_restricted).to_param }
    end
    assert_response :success
  end

  test "should allow to update for restricted user who owns the host" do
    disable_orchestration
    as_user :restricted do
      put :update, { :id => hosts(:owned_by_restricted).to_param, :host => {} }
    end
    assert_response :success
  end

  test "should allow destroy for restricted user who owns the hosts" do
    assert_difference('Host.count', -1) do
      as_user :restricted do
        delete :destroy, { :id => hosts(:owned_by_restricted).to_param }
      end
    end
    assert_response :success
  end

  test "should allow show status for restricted user who owns the hosts" do
    as_user :restricted do
      get :status, { :id => hosts(:owned_by_restricted).to_param }
    end
    assert_response :success
  end

  test "should not allow access to a host out of users hosts scope" do
    as_user :restricted do
      get :show, { :id => hosts(:one).to_param }
    end
    assert_response :not_found
  end

  test "should not list a host out of users hosts scope" do
    as_user :restricted do
      get :index, {}
    end
    assert_response :success
    hosts = ActiveSupport::JSON.decode(@response.body)
    ids = hosts.map { |hash| hash['host']['id'] }
    assert !ids.include?(hosts(:one).id)
    assert ids.include?(hosts(:owned_by_restricted).id)
  end

  test "should not update host out of users hosts scope" do
    as_user :restricted do
      put :update, { :id => hosts(:one).to_param }
    end
    assert_response :not_found
  end

  test "should not delete hosts out of users hosts scope" do
    as_user :restricted do
      delete :destroy, { :id => hosts(:one).to_param }
    end
    assert_response :not_found
  end

  test "should not show status of hosts out of users hosts scope" do
    as_user :restricted do
      get :status, { :id => hosts(:one).to_param }
    end
    assert_response :not_found
  end
end
