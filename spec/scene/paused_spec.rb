describe PausedScene do
  it "changes the character's state after a response" do
    plot = Plot.new
    room = plot.make Room, :name => 'room'
    character = plot.make Character, :name => 'character', :parent => room
    character[:has_paused] = false
    plot.pause :pause do |actor|
      character[:has_paused] = true
    end
    plot.introduce character
    plot.cue character, :pause
    expect(character.scene.key).to eq(:pause)
    character.queue.push ""
    character.update
    expect(character.scene.key).to eq(:active)
    expect(character[:has_paused]).to eq(true)
  end
end
