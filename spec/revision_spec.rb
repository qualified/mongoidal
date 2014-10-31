require 'spec_helper'

describe Revision do
  subject(:example) { RevisableExample.create(age: 10, name: 'test') }
  let(:embedded) { example.revisable_embedded_examples.create(name: 'a') }
  let(:user) { User.create }

  before do
    embedded.name = 'b'
    example.name = 'b'
    example.revise!
    example.name = 'c'
    example.revise!
  end

  it 'should have stored revisions' do
    expect(example.revisions.length).to eq 3
  end

  # TODO: migrate other specs from main app
end