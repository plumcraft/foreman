require 'test_helper'
require 'foreman/renderer'

class RendererTest < ActiveSupport::TestCase
  include Foreman::Renderer

  def setup_normal_renderer
    Setting[:safemode_render] = false
  end

  def setup_safemode_renderer
    Setting[:safemode_render] = true
  end

  test "foreman_url should run with @host as nil" do
    @host = nil
    self.expects(:url_for).returns("url")
    assert_nothing_raised(NoMethodError) { foreman_url }
  end

  [:normal_renderer, :safemode_renderer].each do |renderer_name|
    test "#{renderer_name} is properly configured" do
      send "setup_#{renderer_name}"
      if renderer_name == :normal_renderer
        assert Setting[:safemode_render] == false
      else
        assert Setting[:safemode_render] == true
      end
    end

    test "#{renderer_name} should evaluate template variables" do
      send "setup_#{renderer_name}"
      tmpl = render_safe('<%= @foo %>', [], { :foo => 'bar' })
      assert_equal 'bar', tmpl
    end

    test "#{renderer_name} should evaluate renderer methods" do
      send "setup_#{renderer_name}"
      self.expects(:foreman_url).returns('bar')
      tmpl = render_safe('<%= foreman_url %>', [:foreman_url])
      assert_equal 'bar', tmpl
    end

    test "#{renderer_name} should render a snippet" do
      send "setup_#{renderer_name}"
      snippet = mock("snippet")
      snippet.stubs(:name).returns("test")
      snippet.stubs(:template).returns("content")
      Template.expects(:where).with(:name => "test", :snippet => true).returns([snippet])
      tmpl = snippet('test')
      assert_equal 'content', tmpl
    end

    test "#{renderer_name} should not raise error when snippet is not found" do
      send "setup_#{renderer_name}"
      Template.expects(:where).with(:name => "test", :snippet => true).returns([])
      assert_nil snippet_if_exists('test')
    end

    test "#{renderer_name} should render unnamed template" do
      send "setup_#{renderer_name}"
      tmpl = unattended_render('x<%= @template_name %>')
      assert_equal 'xUnnamed', tmpl
    end

    test "#{renderer_name} should render template name" do
      send "setup_#{renderer_name}"
      template = mock('template')
      template.stubs(:template).returns('x<%= @template_name %>')
      template.stubs(:name).returns('abc')
      tmpl = unattended_render(template)
      assert_equal 'xabc', tmpl
    end
  end
end
