require 'spec_helper'

class GidParent
  include Mongoid::Document
  include Mongoidal::Identification
  field :name, type: String
  embeds_many :kids, class_name: 'GidKid'
end

class GidKid
  include Mongoid::Document
  include Mongoidal::Identification
  embedded_in :gid_parent
  field :name, type: String
end

GlobalID.app = 'mongoidal'

describe Mongoidal::Identification do
  let(:parent) { GidParent.create(name: 'Parent') }
  let(:kid) { parent.kids.create(name: 'Kid') }

  def locate(doc)
    Mongoidal::Locator.new(GlobalID.parse(doc.to_global_id.to_s)).locate
  end

  it 'round trips a root document' do
    expect(locate(parent)).to eq parent
  end

  it 'round trips an embedded document through its root' do
    expect(locate(kid)).to eq kid
  end

  it 'rebuilds a destroyed embedded document from its attributes' do
    gid = kid.to_global_id.to_s
    kid.destroy
    gid = kid.to_global_id.to_s
    found = Mongoidal::Locator.new(GlobalID.parse(gid)).locate
    expect(found.name).to eq 'Kid'
    expect(found).to be_destroyed
  end
end
