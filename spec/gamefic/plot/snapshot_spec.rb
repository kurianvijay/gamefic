describe Gamefic::Plot::Snapshot do
  it "saves entities" do
    plot = Gamefic::Plot.new
    plot.make Gamefic::Entity, name: 'entity'
    snapshot = plot.save
    expect(snapshot[:entities].length).to eq(1)
  end

  it "restores entities" do
    plot = Gamefic::Plot.new
    entity = plot.make Gamefic::Entity, name: 'old name'
    snapshot = plot.save
    entity.name = 'new name'
    plot.restore snapshot
    expect(entity.name).to eq('old name')
  end

  it "saves subplots" do
    plot = Gamefic::Plot.new
    plot.branch Gamefic::Subplot
    snapshot = plot.save
    expect(snapshot[:subplots].length).to eq(1)
  end

  it "restores subplots" do
    plot = Gamefic::Plot.new
    subplot = plot.branch Gamefic::Subplot
    snapshot = plot.save
    subplot.conclude
    expect(subplot.concluded?).to be(true)
    plot.restore snapshot
    expect(plot.subplots.length).to eq(1)
    expect(plot.subplots[0].concluded?).to be(false)
  end
end