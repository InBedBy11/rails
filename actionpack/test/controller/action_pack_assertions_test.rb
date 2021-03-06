require 'abstract_unit'
require 'action_controller/vendor/html-scanner'
require 'controller/fake_controllers'

# a controller class to facilitate the tests
class ActionPackAssertionsController < ActionController::Base

  # this does absolutely nothing
  def nothing() head :ok end

  # a standard template
  def hello_world() render :template => "test/hello_world"; end

  # a standard template
  def hello_xml_world() render :template => "test/hello_xml_world"; end

  # a standard template rendering PDF
  def hello_xml_world_pdf
    self.content_type = "application/pdf"
    render :template => "test/hello_xml_world"
  end

  # a standard template rendering PDF
  def hello_xml_world_pdf_header
    response.headers["Content-Type"] = "application/pdf; charset=utf-8"
    render :template => "test/hello_xml_world"
  end

  # a standard partial
  def partial() render :partial => 'test/partial'; end

  # a redirect to an internal location
  def redirect_internal() redirect_to "/nothing"; end

  def redirect_to_action() redirect_to :action => "flash_me", :id => 1, :params => { "panda" => "fun" }; end

  def redirect_to_controller() redirect_to :controller => "elsewhere", :action => "flash_me"; end

  def redirect_to_controller_with_symbol() redirect_to :controller => :elsewhere, :action => :flash_me; end

  def redirect_to_path() redirect_to '/some/path' end

  def redirect_to_named_route() redirect_to route_one_url end

  # a redirect to an external location
  def redirect_external() redirect_to "http://www.rubyonrails.org"; end

  # a 404
  def response404() head '404 AWOL' end

  # a 500
  def response500() head '500 Sorry' end

  # a fictional 599
  def response599() head '599 Whoah!' end

  # putting stuff in the flash
  def flash_me
    flash['hello'] = 'my name is inigo montoya...'
    render :text => "Inconceivable!"
  end

  # we have a flash, but nothing is in it
  def flash_me_naked
    flash.clear
    render :text => "wow!"
  end

  # assign some template instance variables
  def assign_this
    @howdy = "ho"
    render :inline => "Mr. Henke"
  end

  def render_based_on_parameters
    render :text => "Mr. #{params[:name]}"
  end

  def render_url
    render :text => "<div>#{url_for(:action => 'flash_me', :only_path => true)}</div>"
  end

  def render_text_with_custom_content_type
    render :text => "Hello!", :content_type => Mime::RSS
  end

  # puts something in the session
  def session_stuffing
    session['xmas'] = 'turkey'
    render :text => "ho ho ho"
  end

  # raises exception on get requests
  def raise_on_get
    raise "get" if request.get?
    render :text => "request method: #{request.env['REQUEST_METHOD']}"
  end

  # raises exception on post requests
  def raise_on_post
    raise "post" if request.post?
    render :text => "request method: #{request.env['REQUEST_METHOD']}"
  end

  def get_valid_record
    @record = Class.new do
      def valid?
        true
      end

      def errors
        Class.new do
           def full_messages; []; end
        end.new
      end

    end.new

    render :nothing => true
  end


  def get_invalid_record
    @record = Class.new do

      def valid?
        false
      end

      def errors
        Class.new do
           def full_messages; ['...stuff...']; end
        end.new
      end
    end.new

    render :nothing => true
  end

  # 911
  def rescue_action(e) raise; end
end

# Used to test that assert_response includes the exception message
# in the failure message when an action raises and assert_response
# is expecting something other than an error.
class AssertResponseWithUnexpectedErrorController < ActionController::Base
  def index
    raise 'FAIL'
  end

  def show
    render :text => "Boom", :status => 500
  end
end

class UserController < ActionController::Base
end

module Admin
  class InnerModuleController < ActionController::Base
    def index
      render :nothing => true
    end

    def redirect_to_index
      redirect_to admin_inner_module_path
    end

    def redirect_to_absolute_controller
      redirect_to :controller => '/content'
    end

    def redirect_to_fellow_controller
      redirect_to :controller => 'user'
    end

    def redirect_to_top_level_named_route
      redirect_to top_level_url(:id => "foo")
    end
  end
end

# a test case to exercise the new capabilities TestRequest & TestResponse
class ActionPackAssertionsControllerTest < ActionController::TestCase
  # -- assertion-based testing ------------------------------------------------

  def test_assert_tag_and_url_for
    get :render_url
    assert_tag :content => "/action_pack_assertions/flash_me"
  end

  # test the get method, make sure the request really was a get
  def test_get
    assert_raise(RuntimeError) { get :raise_on_get }
    get :raise_on_post
    assert_equal @response.body, 'request method: GET'
  end

  # test the get method, make sure the request really was a get
  def test_post
    assert_raise(RuntimeError) { post :raise_on_post }
    post :raise_on_get
    assert_equal @response.body, 'request method: POST'
  end

#   the following test fails because the request_method is now cached on the request instance
#   test the get/post switch within one test action
#   def test_get_post_switch
#     post :raise_on_get
#     assert_equal @response.body, 'request method: POST'
#     get :raise_on_post
#     assert_equal @response.body, 'request method: GET'
#     post :raise_on_get
#     assert_equal @response.body, 'request method: POST'
#     get :raise_on_post
#     assert_equal @response.body, 'request method: GET'
#   end

  # test the redirection to a named route
  def test_assert_redirect_to_named_route
    with_routing do |set|
      set.draw do |map|
        match 'route_one', :to => 'action_pack_assertions#nothing', :as => :route_one
        match ':controller/:action'
      end
      set.install_helpers

      process :redirect_to_named_route
      assert_redirected_to 'http://test.host/route_one'
      assert_redirected_to route_one_url
    end
  end

  def test_assert_redirect_to_named_route_failure
    with_routing do |set|
      set.draw do |map|
        match 'route_one', :to => 'action_pack_assertions#nothing', :as => :route_one
        match 'route_two', :to => 'action_pack_assertions#nothing', :id => 'two', :as => :route_two
        match ':controller/:action'
      end
      process :redirect_to_named_route
      assert_raise(ActiveSupport::TestCase::Assertion) do
        assert_redirected_to 'http://test.host/route_two'
      end
      assert_raise(ActiveSupport::TestCase::Assertion) do
        assert_redirected_to :controller => 'action_pack_assertions', :action => 'nothing', :id => 'two'
      end
      assert_raise(ActiveSupport::TestCase::Assertion) do
        assert_redirected_to route_two_url
      end
    end
  end

  def test_assert_redirect_to_nested_named_route
    @controller = Admin::InnerModuleController.new

    with_routing do |set|
      set.draw do |map|
        match 'admin/inner_module', :to => 'admin/inner_module#index', :as => :admin_inner_module
        # match ':controller/:action'
        map.connect ':controller/:action/:id'
      end
      process :redirect_to_index
      # redirection is <{"action"=>"index", "controller"=>"admin/admin/inner_module"}>
      assert_redirected_to admin_inner_module_path
    end
  end

  def test_assert_redirected_to_top_level_named_route_from_nested_controller
    @controller = Admin::InnerModuleController.new

    with_routing do |set|
      set.draw do |map|
        match '/action_pack_assertions/:id', :to => 'action_pack_assertions#index', :as => :top_level
        # match ':controller/:action'
        map.connect ':controller/:action/:id'
      end
      process :redirect_to_top_level_named_route
      # assert_redirected_to "http://test.host/action_pack_assertions/foo" would pass because of exact match early return
      assert_redirected_to "/action_pack_assertions/foo"
    end
  end

  def test_assert_redirected_to_top_level_named_route_with_same_controller_name_in_both_namespaces
    @controller = Admin::InnerModuleController.new

    with_routing do |set|
      set.draw do |map|
        # this controller exists in the admin namespace as well which is the only difference from previous test
        match '/user/:id', :to => 'user#index', :as => :top_level
        # match ':controller/:action'
        map.connect ':controller/:action/:id'
      end
      process :redirect_to_top_level_named_route
      # assert_redirected_to top_level_url('foo') would pass because of exact match early return
      assert_redirected_to top_level_path('foo')
    end
  end

  # -- standard request/response object testing --------------------------------

  # make sure that the template objects exist
  def test_template_objects_alive
    process :assign_this
    assert !@controller.template.instance_variable_get(:"@hi")
    assert @controller.template.instance_variable_get(:"@howdy")
  end

  # make sure we don't have template objects when we shouldn't
  def test_template_object_missing
    process :nothing
    assert_nil @controller.template.assigns['howdy']
  end

  # check the empty flashing
  def test_flash_me_naked
    process :flash_me_naked
    assert_deprecated do
      assert !@response.has_flash?
      assert !@response.has_flash_with_contents?
    end
  end

  # check if we have flash objects
  def test_flash_haves
    process :flash_me
    assert_deprecated do
      assert @response.has_flash?
      assert @response.has_flash_with_contents?
      assert @response.has_flash_object?('hello')
    end
  end

  # ensure we don't have flash objects
  def test_flash_have_nots
    process :nothing
    assert_deprecated do
      assert !@response.has_flash?
      assert !@response.has_flash_with_contents?
      assert_nil @response.flash['hello']
    end
  end

  def test_assert_template_with_partial
    get :partial
    assert_template :partial => '_partial'
  end

  def test_assert_template_with_nil
    get :nothing
    assert_template nil
  end

  def test_assert_template_with_string
    get :hello_world
    assert_template 'hello_world'
  end

  def test_assert_template_with_symbol
    get :hello_world
    assert_template :hello_world
  end

  # check if we were rendered by a file-based template?
  def test_rendered_action
    process :nothing
    assert_nil @controller.template.rendered[:template]

    process :hello_world
    assert @controller.template.rendered[:template]
    assert 'hello_world', @controller.template.rendered[:template].to_s
  end

  # check the redirection location
  def test_redirection_location
    process :redirect_internal
    assert_equal 'http://test.host/nothing', @response.redirect_url

    process :redirect_external
    assert_equal 'http://www.rubyonrails.org', @response.redirect_url
  end

  def test_no_redirect_url
    process :nothing
    assert_nil @response.redirect_url
  end


  # check server errors
  def test_server_error_response_code
    process :response500
    assert @response.server_error?

    process :response599
    assert @response.server_error?

    process :response404
    assert !@response.server_error?
  end

  # check a 404 response code
  def test_missing_response_code
    process :response404
    assert @response.missing?
  end

  # check client errors
  def test_client_error_response_code
    process :response404
    assert @response.client_error?
  end

  # check to see if our redirection matches a pattern
  def test_redirect_url_match
    process :redirect_external
    assert @response.redirect?
    assert_deprecated do
      assert @response.redirect_url_match?("rubyonrails")
      assert @response.redirect_url_match?(/rubyonrails/)
      assert !@response.redirect_url_match?("phpoffrails")
      assert !@response.redirect_url_match?(/perloffrails/)
    end
  end

  # check for a redirection
  def test_redirection
    process :redirect_internal
    assert @response.redirect?

    process :redirect_external
    assert @response.redirect?

    process :nothing
    assert !@response.redirect?
  end

  # check a successful response code
  def test_successful_response_code
    process :nothing
    assert @response.success?
  end

  # a basic check to make sure we have a TestResponse object
  def test_has_response
    process :nothing
    assert_kind_of ActionController::TestResponse, @response
  end

  def test_render_based_on_parameters
    process :render_based_on_parameters, "name" => "David"
    assert_equal "Mr. David", @response.body
  end

  def test_assert_redirection_fails_with_incorrect_controller
    process :redirect_to_controller
    assert_raise(ActiveSupport::TestCase::Assertion) do
      assert_redirected_to :controller => "action_pack_assertions", :action => "flash_me"
    end
  end

  def test_assert_redirection_with_extra_controller_option
    get :redirect_to_action
    assert_redirected_to :controller => 'action_pack_assertions', :action => "flash_me", :id => 1, :params => { :panda => 'fun' }
  end

  def test_redirected_to_url_leading_slash
    process :redirect_to_path
    assert_redirected_to '/some/path'
  end

  def test_redirected_to_url_no_leading_slash_fails
    process :redirect_to_path
    assert_raise ActiveSupport::TestCase::Assertion do
      assert_redirected_to 'some/path'
    end
  end

  def test_redirected_to_url_full_url
    process :redirect_to_path
    assert_redirected_to 'http://test.host/some/path'
  end

  def test_assert_redirection_with_symbol
    process :redirect_to_controller_with_symbol
    assert_nothing_raised {
      assert_redirected_to :controller => "elsewhere", :action => "flash_me"
    }
    process :redirect_to_controller_with_symbol
    assert_nothing_raised {
      assert_redirected_to :controller => :elsewhere, :action => :flash_me
    }
  end

  def test_redirected_to_with_nested_controller
    @controller = Admin::InnerModuleController.new
    get :redirect_to_absolute_controller
    assert_redirected_to :controller => '/content'

    get :redirect_to_fellow_controller
    assert_redirected_to :controller => 'admin/user'
  end

  def test_assert_valid
    get :get_valid_record
    assert_deprecated { assert_valid assigns('record') }
  end

  def test_assert_valid_failing
    get :get_invalid_record

    begin
      assert_deprecated { assert_valid assigns('record') }
      assert false
    rescue ActiveSupport::TestCase::Assertion => e
    end
  end

  def test_assert_response_uses_exception_message
    @controller = AssertResponseWithUnexpectedErrorController.new
    get :index
    assert_response :success
    flunk 'Expected non-success response'
  rescue RuntimeError => e
    assert e.message.include?('FAIL')
  end

  def test_assert_response_failure_response_with_no_exception
    @controller = AssertResponseWithUnexpectedErrorController.new
    get :show
    assert_response :success
    flunk 'Expected non-success response'
  rescue ActiveSupport::TestCase::Assertion
    # success
  rescue
    flunk "assert_response failed to handle failure response with missing, but optional, exception."
  end
end

class ActionPackHeaderTest < ActionController::TestCase
  tests ActionPackAssertionsController

  def test_rendering_xml_sets_content_type
    process :hello_xml_world
    assert_equal('application/xml; charset=utf-8', @response.headers['Content-Type'])
  end

  def test_rendering_xml_respects_content_type
    process :hello_xml_world_pdf
    assert_equal('application/pdf; charset=utf-8', @response.headers['Content-Type'])
  end

  def test_rendering_xml_respects_content_type_when_set_in_the_header
    process :hello_xml_world_pdf_header
    assert_equal('application/pdf; charset=utf-8', @response.headers['Content-Type'])
  end

  def test_render_text_with_custom_content_type
    get :render_text_with_custom_content_type
    assert_equal 'application/rss+xml; charset=utf-8', @response.headers['Content-Type']
  end
end
