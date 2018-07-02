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

  # it 'should properly support updating nested items' do
  #   nested_b.reload
  #   nested_b.name = 'c'
  #   nested_b.save
  #
  #   child.reload
  #
  #   expect(nested_a.reload.name).to eq 'a'
  #   expect(nested_b.reload.name).to eq 'c'
  #
  #   expect(child.items.order_by('name ASC').map(&:name)).to eq ['a', 'c']
  # end

  it 'should properly support updating nested items via parent' do
    nested_b.name = 'c'
    child.save
    child.reload

    expect(child.items.map(&:name)).to eq ['a', 'c']
  end
end
