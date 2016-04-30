module Gamefic

  class Scene::MultipleChoice < Scene::Custom
    autoload :Input, 'gamefic/scene/multiple_choice/input'
    
    def initialize config = {}
      super
      @options = config[:options]
      @invalid_choice_message = config[:invalid_choice_message]
    end
    def start actor
      super
      tell_choices actor
    end
    def finish actor, input
      this_scene = actor.scene
      index = nil
      choice = nil
      if input.strip =~ /[0-9]+/ and input.to_i > 0
        index = input.to_i - 1
        choice = @options[index]
      else
        index = 0
        @options.each { |o|
          if o.casecmp(input).zero?
            choice = o
          end
          index += 1
        }
      end
      if choice.nil?
        actor.tell invalid_choice_message
        tell_choices actor
      else
        input_object = Input.new(input, index, choice)
        super actor, input_object
        actor.cue :active if (actor.scene == this_scene and actor.next_scene.nil?)
      end
    end

    def prompt
      @prompt ||= "Enter a choice:"
    end
    
    def invalid_choice_message
      @invalid_choice_message ||= "That's not a valid selection."
    end
    
    private
    
    def tell_choices actor
      list = '<ol class="multiple_choice">'
      @options.each { |o|
        list += "<li>#{o}</li>"
      }
      list += "</ol>"
      actor.tell list
    end
    
  end

end
