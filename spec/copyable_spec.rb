require 'spec_helper'

class CopyableChild
  include Mongoid::Document
  field :label

  embedded_in :copyable_example
end

class CopyableExample
  include Mongoid::Document
  include Mongoidal::Copyable

  field :name, type: String
  field :address, type: String

  embeds_many :copyable_childs
end

describe Mongoidal::Copyable do
  let(:a) { CopyableExample.new(name: 'name', address: 'address') }
  let(:b) { CopyableExample.new }
  let(:a_child) { a.copyable_childs.build(label: 'a') }
  let(:b_child) { b.copyable_childs.first }

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
    before { a_child.save }
    before { a.copy_to(b) }

    it 'should copy fields' do
      b.save
      b.reload
      expect(b.name).to eq a.name
      expect(b.address).to eq a.address
      expect(b_child.label).to eq 'a'
      expect(b_child.id).not_to eq a_child.id
    end

    it 'should not copy id' do
      expect(b.id).not_to eq a.id
    end
  end
end