# TODO: JSON support is currently experimental.
#require 'gamefic/entityloader'
require 'gamefic/stage'
require 'gamefic/tester'
require 'gamefic/source'
require 'gamefic/script'
require 'gamefic/query'

module Gamefic

  class Plot
    autoload :SceneMount, 'gamefic/plot/scene_mount'
    autoload :CommandMount, 'gamefic/plot/command_mount'
    autoload :Entities, 'gamefic/plot/entities'
    autoload :ArticleMount, 'gamefic/plot/article_mount'
    autoload :YouMount, 'gamefic/plot/you_mount'
    autoload :Snapshot, 'gamefic/plot/snapshot'
    autoload :Host, 'gamefic/plot/host'
    autoload :Players, 'gamefic/plot/players'
    autoload :Playbook, 'gamefic/plot/playbook'
    autoload :Callbacks, 'gamefic/plot/callbacks'

    attr_reader :commands, :imported_scripts, :rules, :asserts, :source
    # TODO: Metadata could use better protection
    attr_accessor :metadata
    include Stage
    mount Gamefic, Tester, Players, SceneMount, CommandMount, Entities,
      ArticleMount, YouMount, Snapshot, Host, Callbacks
    expose :script, :assert_action, :on_update, :on_player_update, :entities,
      :on_ready, :on_player_ready, :players, :metadata
    
    # @param [Source::Base]
    def initialize(source = nil)
      @source = source || Source::Text.new({})
      @working_scripts = []
      @imported_scripts = []
      @asserts = {}
      @subplots = []
      @running = false
      @playbook = Playbook.new
      post_initialize
    end

    def playbook
      @playbook ||= Playbook.new
    end

    def running?
      @running
    end
        
    # Get an Array of all scripts that have been imported into the Plot.
    #
    # @return [Array<Script>] The imported scripts
    def imported_scripts
      @imported_scripts ||= []
    end
    
    # Add a Block to be executed for the given verb.
    # If the block returns false, the Action is cancelled.
    #
    # @example Require the player to have a property enabled before performing the Action.
    #   assert_action :authorize do |actor, verb, arguments|
    #     if actor[:can_authorize] == true
    #       true
    #     else
    #       actor.tell "You don't have permission to use the authorize command."
    #       false
    #     end
    #   end
    #
    # @yieldparam [Character] The character performing the Action.
    # @yieldparam [Symbol] The verb associated with the Action.
    # @yieldparam [Array] The arguments that will be passed to the Action's #execute method.
    def assert_action name, &block
      @asserts[name] = Assert.new(name, &block)
    end
    
    def post_initialize
      # TODO: Should this method be required by extended classes?
    end
    
    # Get an Array of the Plot's current Syntaxes.
    #
    # @return [Array<Syntax>]
    def syntaxes
      playbook.syntaxes
    end
    
    # Prepare the Plot for the next turn of gameplay.
    # This method is typically called by the Engine that manages game execution.
    def ready
      playbook.freeze
      @running = true
      call_ready
      call_player_ready
      p_subplots.each { |s| s.ready }
    end
    
    # Update the Plot's current turn of gameplay.
    # This method is typically called by the Engine that manages game execution.
    def update
      p_players.each { |p| process_input p }
      p_entities.each { |e| e.update }
      call_player_update
      call_update
      p_subplots.each { |s| s.update unless s.concluded? }
      p_subplots.delete_if { |s| s.concluded? }
    end

    def tell entities, message, refresh = false
      entities.each { |entity|
        entity.tell message, refresh
      }
    end

    # Load a script into the current Plot.
    # This method is similar to Kernel#require, except that the script is
    # evaluated within the Plot's context via #stage.
    #
    # @param path [String] The path to the script being evaluated
    # @return [Boolean] true if the script was loaded by this call or false if it was already loaded.
    def script path
      imported_script = source.export(path)
      if imported_script.nil?
        raise LoadError.new("cannot load script -- #{path}")
      end
      if !@working_scripts.include?(imported_script) and !imported_scripts.include?(imported_script)
        @working_scripts.push imported_script
        stage imported_script.read, imported_script.absolute_path
        @working_scripts.pop
        imported_scripts.push imported_script
        true
      else
        false
      end
    end
    
    private

    def process_input player
      line = player.queue.shift
      if !line.nil?
        player.scene.finish player, line
      end
    end

  end

end
