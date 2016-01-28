require 'spec_helper'

class PermittableExample
  include Mongoid::Document
  include Mongoidal::Permittable
  include Mongoidal::EnumField

  permitted enum_field :bin, type: Symbol, values: [:hungry, :bored]
  permitted field :name
  permitted field :items, type: Array

  permit_fields!
end

class NestedPermittableExample
  include Mongoid::Document
  include Mongoidal::Permittable

  permitted :id
  permitted embedded_in :permittable_example
end

describe Mongoidal::Permittable do
  context 'RootDocuments' do
    subject { PermittableExample }
    its(:permitted_fields) { should include :bin }
    its(:permitted_fields) { should include :name }
    its(:permitted_fields) { should_not include :id }
    its('permitted_fields.last') { should be_a Hash }
  end

  context 'Embedded Documents' do
    subject { NestedPermittableExample }
    its(:permitted_fields) { should include :id }
  end
end