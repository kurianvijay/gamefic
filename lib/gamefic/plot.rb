require 'gamefic/character/state'

module Gamefic

  # Constant shortcuts for common character states
  ACTIVE = CharacterState::Active
  PAUSED = CharacterState::Paused
  PROMPTED = CharacterState::Prompted
  CONCLUDED = CharacterState::Concluded

  def self.bind(plot)
    mod = Module.new do
      def self.bind(plot)
        @@plot = plot
      end
      def self.get_binding
        binding
      end
      def self.method_missing(method_name, *args, &block)
        if @@plot.respond_to?(method_name)
          if method_name == :action or method_name == :respond or method_name == :assert_action or method_name == :finish_action or method_name == :meta
            result = @@plot.send method_name, *args, &block
            parts = caller[0].split(':')[0..-2]
            line = parts.pop
            file = parts.join(':').gsub(/\/+/, '/')
            # The caller value shouldn't really be user-definable, so we're
            # injecting it into the instance variable instead of defining a
            # writer method in the receiver.
            result.instance_variable_set(:@caller, "#{file}, line #{line}")
          else
            @@plot.send method_name, *args, &block
          end
        elsif Gamefic.respond_to?(method_name)
          Gamefic.send method_name, *args, &block
        end
      end
    end
    mod.bind plot
    mod.get_binding
  end
  
	class Plot
		attr_reader :scenes, :commands, :conclusions, :imported_scripts, :rules, :asserts, :finishes, :states
		attr_accessor :story
    include OptionMap
    def self.common_import_dir
      "#{File.dirname(__FILE__)}/import"
    end
		def commandwords
			words = Array.new
			@syntaxes.each { |s|
        word = s.template[0]
				words.push(word) if !word.kind_of?(Symbol)
			}
			words.uniq
		end
		def initialize
			@scenes = Hash.new
			@commands = Hash.new
			@syntaxes = Array.new
			@conclusions = Hash.new
			@update_procs = Array.new
      @player_procs = Array.new
			@imported_scripts = Array.new
      @imported_identifiers = Array.new
			@entities = Array.new
      @players = Array.new
      @asserts = Hash.new
      @finishes = Hash.new
      @states = Hash.new
      @states[:active] = CharacterState::Active.new
      @states[:concluded] = CharacterState::Concluded.new
			post_initialize
		end
    def assert_action name, &block
      @asserts[name] = Assert.new(name, &block)
    end
    def finish_action name, &block
      @finishes[name] = block #Finish.new(name, &block)
    end
		def post_initialize
      # TODO: Should this method be required by extended classes?
		end
		def meta(command, *queries, &proc)
			act = Meta.new(self, command, *queries, &proc)
		end
		def action(command, *queries, &proc)
			act = Action.new(self, command, *queries, &proc)
		end
		def respond(command, *queries, &proc)
			self.action(command, *queries, &proc)
		end
		def make(cls, args = {})
			ent = cls.new(self, args)
			if ent.kind_of?(Entity) == false
				raise "Invalid entity class"
			end
			ent
		end
    def pause name, *args, &block
      @states[name] = CharacterState::Paused.new(*args, &block)
    end
    def prompt name, *args, &block
      @states[name] = CharacterState::Prompted.new(*args, &block)
    end
    def yes_or_no name, *args, &block
      @states[name] = CharacterState::YesOrNo.new(*args, &block)
    end
    def multiple_choice name, *args, &block
      @states[name] = CharacterState::MultipleChoice.new(*args, &block)
    end
		def syntax(*args)
      xlate *args
		end
		def xlate(*args)
			syn = Syntax.new(self, *args)
			@syntaxes.push syn
			syn
		end
		def entities
			@entities.clone
		end
		def syntaxes
			@syntaxes.clone
		end
		def on_update(&block)
			@update_procs.push block
		end
		def introduction (&proc)
			@introduction = proc
		end
		def conclusion(key, &proc)
			@conclusions[key] = proc
		end
		def scene(key, &proc)
			@scenes[key] = proc
		end
		def introduce(player)
      @players.push player
			if @introduction != nil
				@introduction.call(player)
			end
      if player.parent.nil?
        rooms = entities.that_are(Room)
        if rooms.length == 0
          room = make(Room, :name => 'nowhere')
          player.parent = room
        else
          player.parent = rooms[0]
        end
      end
		end
		def conclude(player, key = nil)
			if key != nil and @conclusions[key]
				@conclusions[key].call(player)
        player.state = :concluded
			end
		end
		def cue actor, scene
			@scenes[scene].call(actor)
		end
		def passthru
			Director::Delegate.passthru
		end
		def update
			@update_procs.each { |p|
				p.call
			}
      @entities.each { |e|
				e.update
			}
      @players.each { |player|
        @player_procs.each { |proc|
          proc.call player
        }
      }
		end

		def tell entities, message, refresh = false
			entities.each { |entity|
				entity.tell message, refresh
			}
		end

    def load script, with_libs = true
      @source_directory = File.dirname(script)
      code = File.read(script)
      eval code, ::Gamefic.bind(self), script, 1
    end
    
    def import script
      script.gsub!(/\/+/, '/')
      if script[0, 1] == '/'
        script = script[1..-1]
      end
      if script[-2, 2] == '/*'
        directory = script[0..-3]
        resolved = directory
        if !@source_directory.nil?
          Dir["#{@source_directory}/#{script}"].each { |f|
            import f[@source_directory.length..-1]
          }
        end
        Dir["#{Plot.common_import_dir}/#{script}"].each { |f|
          import f[Plot.common_import_dir.length..-1]
        }
      else
        resolved = script
        base = nil
        found = false
        if !@source_directory.nil?
          if File.file?("#{@source_directory}/#{resolved}")
            base = @source_directory
            found = true
          elsif File.file?("#{@source_directory}/#{resolved}.rb")
            base = @source_directory
            resolved = resolved + '.rb'
            found = true
          end
        end
        if !found
          if File.file?("#{Plot.common_import_dir}/#{resolved}")
            base = Plot.common_import_dir
            found = true
          elsif File.file?("#{Plot.common_import_dir}/#{resolved}.rb")
            base = Plot.common_import_dir
            resolved = resolved + '.rb'
            found = true
          end
        end
        if found
          if @imported_identifiers.include?(resolved) == false
            code = File.read("#{base}/#{resolved}")
            @imported_identifiers.push resolved
            @imported_scripts.push "#{base}/#{resolved}"
            eval code, Gamefic.bind(self), "#{base}/#{resolved}", 1
          end
        else
          raise "Unavailable import: #{script}"
        end
      end
    end
    def on_player_update &block
      @player_procs.push block
    end
    
		private
		def rem_entity(entity)
			@entities.delete(entity)
		end
		def recursive_update(entity)
			entity.update
			entity.children.each { |e|
				recursive_update e
			}
		end	
		def add_syntax syntax
			if @commands[syntax.command] == nil
				raise "Action \"#{syntax.command}\" does not exist"
			end
			@syntaxes.unshift syntax
			@syntaxes.sort! { |a, b|
				al = a.template.length
        if (a.command.nil?)
          al -= 1
        end
				bl = b.template.length
        if (b.command.nil?)
          bl -= 1
        end
				if al == bl
					# For syntaxes of the same length, creation order takes precedence
					0
				else
					bl <=> al
				end
			}			
		end
		def add_action(action)
			if (@commands[action.command] == nil)
				@commands[action.command] = Array.new
			end
			@commands[action.command].unshift action
			@commands[action.command].sort! { |a, b|
        if a.specificity == b.specificity
          # Newer action takes precedence
          b.order_key <=> a.order_key
        else
          # Higher specificity takes precedence
          b.specificity <=> a.specificity
        end
			}
      #if action.command != nil
        user_friendly = action.command.to_s.sub(/_/, ' ')
        args = Array.new
        used_names = Array.new
        action.queries.each { |c|
          num = 1
          new_name = "var"
          while used_names.include? new_name
            num = num + 1
            new_name = "var#{num}"
          end
          used_names.push new_name
          user_friendly += " :#{new_name}"
          args.push new_name.to_sym
        }
        Syntax.new self, *[user_friendly.strip, action.command] + args
      #end
		end
    def rem_action(action)
      @commands[action.command].delete(action)
    end
    def rem_syntax(syntax)
      @syntaxes.delete syntax
    end
		def add_entity(entity)
			@entities.push entity
		end
  end

end
