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
  end

  # TODO: migrate other specs from main app
end