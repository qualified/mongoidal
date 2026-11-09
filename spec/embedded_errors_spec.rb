require 'spec_helper'

class EmbeddedErrorsParent
  include Mongoid::Document
  include Mongoidal::EmbeddedErrors

  embeds_many :kids, class_name: 'EmbeddedErrorsKid'
  field :name, type: String

  validates :name, presence: true
  validates_associated :kids
end

class EmbeddedErrorsKid
  include Mongoid::Document

  embedded_in :embedded_errors_parent
  field :age, type: Integer

  validates :age, presence: true
end

describe Mongoidal::EmbeddedErrors do
  let(:parent) { EmbeddedErrorsParent.new }

  describe '#embedded_errors' do
    it 'returns a plain hash of attribute errors' do
      parent.valid?
      expect(parent.embedded_errors.transform_keys(&:to_sym)).to eq(name: ["can't be blank"])
    end

    it 'adds the invalid embedded record errors under "<relation>_errors"' do
      parent.name = 'Parent'
      parent.kids.build
      parent.valid?

      errors = parent.embedded_errors
      expect(errors.keys.map(&:to_s)).to include('kids', 'kids_errors')
      expect(errors['kids_errors'].messages[:age]).to eq(["can't be blank"])
    end
  end
end
