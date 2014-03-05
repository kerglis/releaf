require 'gravatar_image_tag'
require 'jquery-cookie-rails'
require 'rails-settings-cached'
require 'stringex'
require 'strong_parameters'
require 'tinymce-rails'
require 'will_paginate'
require 'font-awesome-rails'
require 'haml'
require 'haml-rails'
require 'jquery-rails'
require 'acts_as_list'
require 'awesome_nested_set'
require 'devise'
require 'dragonfly'
require 'globalize'
require 'globalize-accessors'

module Releaf
  class Engine < ::Rails::Engine
    initializer "releaf.insert_middleware" do |app|
      if Releaf.load_routes_middleware
        app.middleware.use Releaf::RoutesReloader
      end
    end
  end

  ActiveSupport.on_load :action_controller do
    ActionDispatch::Routing::Mapper.send(:include, Releaf::RouteMapper)
  end
end
