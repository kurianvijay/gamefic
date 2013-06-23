Action.new story, :look do |actor|
	actor.perform "itemize room full"
end

Action.new story, :look_around do |actor|
	actor.perform "look"
end

Action.new story, :itemize_room, Query.new(:string) do |actor, option|
	actor.tell "#{actor.parent.longname.cap_first}"
	if option == "full"
		actor.tell actor.parent.description
	end
	chars = actor.parent.children.that_are(Character) - [actor]
	if chars.length > 0
		actor.tell "Others here: #{chars.join(", ")}"
	end
	#items = actor.parent.children.that_are(Itemized) - [chars] - [actor] - actor.parent.children.that_are(Portal)
	items = actor.parent.children.that_are(Itemized)
	if items.length > 0
		actor.tell "Visible items: #{items.join(", ")}"
	end
	portals = actor.parent.children.that_are(Portal)
	if portals.length > 0
		actor.tell "Obvious exits: #{portals.join(', ')}"
	else
		actor.tell "Obvious exits: none"	
	end
end
Syntax.new story, "itemize room", :itemize_room, "short"
Syntax.new story, "itemize room :option", :itemize_room, :option

Action.new story, :look, Query.new(:family) do |actor, thing|
	actor.tell thing.description
end

Action.new story, :look, Query.new(:parent) do |actor, thing|
	actor.perform "look"
end

Action.new story, :look, String do |actor, string|
	actor.tell "You don't see any \"#{string}\" here."
end

Syntax.new story, "look at :thing", :look, :thing
Syntax.new story, "examine :thing", :look, :thing
Syntax.new story, "exam :thing", :look, :thing
Syntax.new story, "x :thing", :look, :thing