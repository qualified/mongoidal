require 'spec_helper'

class PermittableExample
  include Mongoid::Document
  include Mongoidal::Permittable
  include Mongoidal::EnumField

  unpermitted enum_field :bin, type: Symbol, values: [:hungry, :bored]

  field :name

  permit_fields!
end

class NestedPermittableExample
  include Mongoid::Document
  include Mongoidal::Permittable

  embedded_in :permittable_example

  permit_fields!
end

describe Mongoidal::Permittable do
  context 'RootDocuments' do
    subject { PermittableExample }
    its(:unpermitted_fields) { should include :bin }
    its(:permitted_fields) { should include :name }
    its(:permitted_fields) { should_not include :id }
  end

  context 'Embedded Documents' do
    subject { NestedPermittableExample }
    its(:permitted_fields) { should include :id }
  end
end