require 'spec_helper'

class FieldCallbacksExample
  include Mongoid::Document
  include Mongoidal::FieldCallbacks

  field :name
  field :title
  field :before_count, type: Integer, default: 0
  field :after_count, type: Integer, default: 0

  before_field_save :name do
    self.before_count += 1
  end

  after_field_save :name, :increase_count

  protected

  def increase_count
    self.after_count += 1
  end
end

describe Mongoidal::FieldCallbacks do
  subject { FieldCallbacksExample.create }

  context 'when name is saved' do
    before do
      subject.name = 'test'
      subject.save!
    end

    its(:before_count) { should eq 1 }
    its(:after_count) { should eq 1 }
  end

  context 'when name is not saved' do
    before do
      subject.title = 'test'
      subject.save!
    end

    its(:before_count) { should eq 0 }
    its(:after_count) { should eq 0 }
  end
end