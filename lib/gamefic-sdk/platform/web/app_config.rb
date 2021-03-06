require 'erb'

module Gamefic
  module Sdk
    class Gamefic::Sdk::Platform::Web::AppConfig
      include Plot::Theater
      attr_reader :javascripts, :stylesheets, :resource_paths, :source_dir, :config, :html_dir
      #expose :javascripts, :stylesheets, :resource_paths
      
      # @param source_dir [String] The directory containing the resources (config file, HTML template, etc.) for this build
      def initialize source_dir, config, js
        @javascripts = []
        @stylesheets = []
        @source_dir = source_dir
        @config = config
        @html_dir = resolve_html_dir
        #@game_config = PlotConfig.new("#{source_dir}/config.yaml")
        @resource_paths = ["#{html_dir}", Gamefic::Sdk::HTML_TEMPLATE_PATH]
        config_file = "#{html_dir}/index.rb"
        stage File.read(config_file), config_file
        javascripts.concat js
      end
      
      # @return [BuildConfig::Data]
      def data
        Data.new config, @javascripts, @stylesheets
      end
      
      # Render HTML using the build config data
      #
      # @return [String] The resulting HTML
      def render
        erb = ERB.new(File.read(html_dir + "/index.html.erb"))
        erb.result data.get_binding
      end
      
      private
      
      def resolve_html_dir
        dir = "#{source_dir}/html"
        if !File.directory?(dir) and config.data['html_skin'].to_s != ''
          dir = "#{Gamefic::Sdk::HTML_TEMPLATE_PATH}/skins/#{config['html_skin']}"
        end
        if !File.directory?(dir)
          dir = "#{Gamefic::Sdk::HTML_TEMPLATE_PATH}/skins/standard"
        end
        if !File.directory?(dir)
          raise "Could not resolve HTML directory"
        end
        dir
      end
    end
  end
end

class Gamefic::Sdk::Platform::Web::AppConfig::Data
  attr_reader :author, :title, :javascripts, :stylesheets
  def initialize config, javascripts, stylesheets
    @author = config.author
    @title = config.title
    @javascripts = javascripts
    @stylesheets = stylesheets
  end
  def javascript_tags
    result = ""
    javascripts.each { |js|
      result += "<script type=\"text/javascript\" src=\"#{js}\"></script>"
    }
    result
  end
  def stylesheet_tags
    result = ""
    stylesheets.each { |css|
      result += "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{css}\" />"
    }
    result
  end
  def get_binding
    binding()
  end
end
