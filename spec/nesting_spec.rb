require 'spec_helper'

class NestParent
  include Mongoid::Document
  include Mongoidal::Nesting
  embeds_many :kids, class_name: 'NestKid', cascade_callbacks: true
  embeds_one :favorite, class_name: 'NestKid'
  field :name, type: String
end

class NestKid
  include Mongoid::Document
  embedded_in :nest_parent

  field :name, type: String
  field :age, type: Integer
  field :description, type: String
  field :_position, type: Integer

  attr_reader :update_fired

  after_update do
    @update_fired = true
  end

  def self.find_within_collection(collection, attrs)
    collection.where(name: attrs[:name]).first
  end
end

describe Mongoidal::Nesting do
  let(:parent) { NestParent.create(name: 'Parent') }

  context 'embeds_many' do
    let!(:kid1) { parent.kids.create(name: 'Kid 1', age: 1) }
    let!(:kid2) { parent.kids.create(name: 'Kid 2', age: 2) }

    it 'should have kids' do
      expect(parent.kids.count).to eq 2
    end

    describe 'update, insert and delete' do
      before do
        data = {
          kids: [{
             id: kid1.id.to_s,
             description: 'test'
           },{
             name: 'Kid 3'
           }]
        }
        parent.nested_save!(data)
      end

      it 'should delete any items that were not matched' do
        expect(kid2).to be_destroyed
        expect(parent.reload.kids.where(age: 2)).to_not be_any
      end

      it 'should update existing matched data' do
        expect(kid1.description).to eq 'test'
      end

      it 'should call update callback' do
        expect(kid1.description).to eq 'test'
        expect(kid1.update_fired).to be true
      end

      it 'should not overwrite attributes that were not supplied' do
        expect(kid1.age).to eq 1
      end

      it 'should have created a new record for new data' do
        expect(parent.kids.last.name).to eq 'Kid 3'
      end
    end

    it 'should match using find_within_collection' do
      parent.nested_save!(kids:[{name: 'Kid 1', age: 4}])
      expect(kid1.age).to eq 4
    end

    describe 'preserving update order' do
      before do
        data = {
          kids: [
            { name: 'Kid 3' },
            {id: kid1.id.to_s, description: '123' }
          ]
        }
        parent.nested_save!(data, position: :_position)
      end

      it 'should preserve order using _position' do
        parent.reload
        kids = parent.kids.order_by('_position ASC').to_a
        expect(kids.first.name).to eq 'Kid 3'
        expect(kids.last.description).to eq '123'
        expect(kids.last.id).to eq kid1.id
      end
    end
  end

  context 'embeds_one' do
    let!(:favorite) { parent.create_favorite(name: 'Kid 1', age: 1) }

    # this is standard functionality
    it 'should update existing favorite' do
      expect(parent.favorite.name).to eq 'Kid 1'
      parent.nested_assign(favorite: {name: 'Kid 2'})
      expect(parent.favorite.id).to eq favorite.id
    end
  end

end
