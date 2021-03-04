require 'spec_helper'

describe Revision do
  subject(:example) { RevisableExample.create(age: 10, name: 'test') }
  let(:embedded) { example.revisable_embedded_examples.create(name: 'a') }
  let(:user) { User.create }

  describe 'embedded revisions' do
    before do
      example.name = 'b'
      example.valid?
      example.revise!
      example.revise!
    end

    it 'should have stored revisions' do
      expect(example.revisions.length).to eq 2
      expect(example.revisions[1].revised_attributes['name']).to eq 'b'
      expect(example.reload.revisions[1].revised_attributes['name']).to eq 'b'
    end
  end

  describe 'embedded revisions' do
    before do
      embedded.name = 'b'
      example.name = 'b'
      example.valid?
      example.revise!
      example.name = 'c'
      example.revise!
    end

    it 'should have stored revisions' do
      expect(example.revisions.length).to eq 3
    end

    describe '#restore!' do
      it 'should restore back to specific revision' do
        age = example.age
        name = example.name
        revision = example.revisions.to_a.last
        example.age = 5
        example.revise!
        example.name = 'test'
        example.revise!
        expect(example.name).to eq 'test'
        expect(example.age).to eq 5
        revision.restore!
        expect(example.name).to eq name
        expect(example.age).to eq age
        rev = example.revisions.to_a.last
        expect(rev.tag).to eq 'restored'
        expect(rev.revised_keys).to eq ['age', 'name']
      end

    end

  end

  # TODO: migrate other specs from main app
end