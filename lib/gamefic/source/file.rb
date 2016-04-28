module Gamefic

  class Source::File < Source::Base
    @@extensions = ['.plot.rb', '.plot', '.rb']
    attr_reader :directories
    attr_accessor :main_dir
    def initialize(*directories)
      @directories = directories || []
    end
    def export path
      @directories.each { |directory|
        @@extensions.each { |ext|
          abs_file = directory + '/' + path + ext
          if File.file?(abs_file)
            return Script::File.new(abs_file, path)
          end
        }
      }
      raise "Script #{path} not found"
    end
  end

end
