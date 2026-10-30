require 'spec_helper'

class BulkParent
  include Mongoid::Document
  include Mongoidal::BulkSavable
  field :name, type: String
  embeds_many :kids, class_name: 'BulkKid'
end

class BulkKid
  include Mongoid::Document
  embedded_in :bulk_parent
  field :name, type: String
end

describe Mongoidal::BulkSavable do
  let(:parent) { BulkParent.create(name: 'Parent') }
  let!(:kid1) { parent.kids.create(name: 'Kid 1') }
  let!(:kid2) { parent.kids.create(name: 'Kid 2') }

  # with no embeds given, every embeds_many relation is used
  it 'updates, adds and flags deletes across embeds_many relations' do
    to_delete = parent.bulk_assign(
      'name' => 'Renamed',
      'kids' => [
        { 'id' => kid1.id.to_s, 'name' => 'Kid 1b' },
        { 'id' => kid2.id.to_s, 'deleted' => true },
        { 'name' => 'Kid 3' }
      ]
    )

    expect(parent.name).to eq 'Renamed'
    expect(parent.kids.map(&:name)).to match_array ['Kid 1b', 'Kid 2', 'Kid 3']
    expect(to_delete).to eq [kid2]
  end

  it 'accepts an explicit list of embeds' do
    parent.bulk_assign({ kids: [{ id: kid1.id, name: 'Kid 1b' }] }, :kids)
    expect(parent.kids.find(kid1.id).name).to eq 'Kid 1b'
  end
end
