require 'spec_helper'

class InstanceCbExample
  include Mongoid::Document
  include Mongoidal::InstanceCallbacks

  field :name
end

describe Mongoidal::InstanceCallbacks do
  let(:fresh) { InstanceCbExample.new }
  let(:existing) { InstanceCbExample.create}

  def fire_only_once(model, event, method)
    fired = 0
    model.send("after_#{event}") { fired += 1 }
    model.name = 'a'
    model.send(method)
    model.name = 'b'
    model.send(method)
    expect(fired).to eq 1
  end

  describe '#after_create' do
    it 'should fire only once' do
      fire_only_once(fresh, :create, :save)
    end
  end

  describe '#after_update' do
    it 'should fire only once' do
      fire_only_once(existing, :update, :save)
    end
  end

  describe '#after_save' do
    it 'should fire only once' do
      fire_only_once(existing, :save, :save)
    end
  end

  describe '#after_destroy' do
    it 'should fire' do
      fired = false
      existing.after_destroy { fired = true }
      existing.destroy
      expect(fired).to eq true
    end
  end
end