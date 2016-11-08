require 'spec_helper'

class BasicParent
  include Mongoid::Document

  field :name
  embeds_many :items, class_name: 'BasicChild'
end

class BasicChild
  include Mongoid::Document

  embedded_in :basic

  field :name
  embeds_many :items, class_name: 'BasicSubChild'
end

class BasicSubChild
  include Mongoidal::EmbeddedDocument

  embedded_in :basic
  field :name
end

describe BasicParent do
  let(:parent) { BasicParent.create(name: 'a') }
  let(:child) { parent.items.create(name: 'a') }
  let!(:nested_a) { child.items.create(name: 'a') }
  let!(:nested_b) { child.items.create(name: 'b') }

  it 'should properly support updating nested items' do
    nested_b.name = 'c'
    nested_b.save

    child.reload

    expect(child.items.map(&:name)).to eq ['a', 'c']
    # p nested_b._updates
    # p nested_b._index
    # p nested_b.atomic_position
    # p nested_b.atomic_selector
    # p nested_b._updates
    # p nested_b.send(:positionally, nested_b.atomic_selector, nested_b._updates)
  end

  it 'should properly support updating nested items via parent' do
    nested_b.name = 'c'
    child.save
    child.reload

    expect(child.items.map(&:name)).to eq ['a', 'c']
  end
end
