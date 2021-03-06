require "active_resource"
require "rails"

module ActiveResource
  class Railtie < Rails::Railtie
    railtie_name :active_resource

    require "active_resource/railties/log_subscriber"
    log_subscriber ActiveResource::Railties::LogSubscriber.new

    initializer "active_resource.set_configs" do |app|
      app.config.active_resource.each do |k,v|
        ActiveResource::Base.send "#{k}=", v
      end
    end
  end
end