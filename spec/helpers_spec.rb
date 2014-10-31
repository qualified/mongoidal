require 'spec_helper'

class DocumentExample
  include Mongoid::Document
  include Mongoidal::Helpers

  field :name
end

describe Mongoidal::Helpers do
  subject(:example) { DocumentExample.new(name: 'test') }

  describe '#slice' do
    it 'should return a hash with selected fields' do
      expect(example.slice(:name)[:name]).to eq 'test'
      expect(example.slice(:name).count).to be 1
    end
  end

  describe '#revert_fields' do
    let(:example) { DocumentExample.create(name: 'test') }

    context 'when fields changed' do
      before { example.name = 'test2' }

      it 'should revert field back to original' do
        example.revert_fields
        expect(example.name).to eq 'test'
      end

      its(:revert_fields) { should eq ['name'] }
    end
  end
end