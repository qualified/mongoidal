require 'spec_helper'

class CopyableExample
  include Mongoid::Document
  include Mongoidal::Copyable

  field :name, type: String
  field :address, type: String
end

describe Mongoidal::Copyable do
  let(:a) { CopyableExample.new(name: 'name', address: 'address') }
  let(:b) { CopyableExample.new }

  describe '#copy_changes_to' do
    before do
      a.name = '1'
      a.address = '2'
    end

    it 'should copy specific fields' do
      a.copy_changes_to(b, :name)
      expect(b.name).to eq '1'
      expect(b.address).to be_nil
    end

    it 'should copy all fields' do
      a.copy_changes_to(b)
      expect(b.name).to eq '1'
      expect(b.address).to eq '2'
    end
  end

  describe '#copy_to' do
    before { a.copy_to(b) }

    it 'should copy fields' do
      expect(b.name).to eq a.name
      expect(b.address).to eq a.address
    end

    it 'should not copy id' do
      expect(b.id).not_to eq a.id
    end
  end
end