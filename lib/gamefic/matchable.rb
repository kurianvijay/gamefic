module Gamefic
  module Matchable
    SPLIT_REGEXP = /[\s]+/

    # Get an array of keywords associated with this object.
    # The default implementation splits the value of self.to_s into an array.
    #
    # @return [Array<String>]
    def keywords
      self.to_s.downcase.split(SPLIT_REGEXP).uniq
    end

    # Determine if this object matches the provided description.
    # In a regular match, every word in the description must be a keyword.
    # Fuzzy matches accept words if a keyword starts with it, e.g., "red"
    # would be a fuzzy match for "reddish."
    #
    # @example
    #   dog = "big red dog"
    #   dog.extend Gamefic::Matchable
    #
    #   dog.match?("red dog")  #=> true
    #   dog.match?("gray dog") #=> false
    #   dog.match?("red do")   #=> false
    #
    #   dog.match?("re do", fuzzy: true)  #=> true
    #   dog.match?("red og", fuzzy: true) #=> false
    #
    # @return [Boolean]
    def match? description, fuzzy: false
      words = description.split(SPLIT_REGEXP)
      return false if words.empty?
      matches = 0
      available = keywords
      words.each { |w|
        if fuzzy
          available.each { |k|
            if k.gsub(/[^a-z0-9]/, '').start_with?(w.downcase.gsub(/[^a-z0-9]/, ''))
              matches +=1
              break
            end
          }
        else
          matches +=1 if available.include?(w.downcase)
        end
      }
      matches == words.length
    end
  end
end
