require 'spec_helper'

class SlugExample
  include Mongoid::Document
  include Mongoidal::SlugField

  slug_field :name
end

describe Mongoidal::SlugField do
  subject(:example) { SlugExample.create(name: 'test slug') }

  it { should validate_presence_of :name }
  its(:slug) { should eq 'test-slug' }
  its(:name) { should eq 'test slug' }

  describe '::any_slug' do
    it 'should be a criteria' do
      expect(SlugExample.any_slug('test')).to be_a Mongoid::Criteria
    end
  end
end
