require 'spec_helper'

class EnumExample
  include Mongoid::Document
  include Mongoidal::Helpers
  include Mongoidal::EnumField

  enum_field :role, type: Symbol, default: :standard, allow_nil: true, suffix: false, prefix: '', values: [
      :admin,
      :standard
  ]

  enum_field :bin, type: Symbol, values: [:hungry, :bored]

  enum_field :grades, type: Array, values: [:a, :b, :c, :d, :e, :f]

end

describe Mongoidal::EnumField do
  subject(:example) { EnumExample.new(bin: :hungry, role: :admin) }

  describe '.enum_fields' do
    it 'should define field name and values as a hash' do
      expect(EnumExample.enum_fields[:role][:values]).to be EnumExample.role_values
    end
  end

  describe 'allow nil values' do
    before { example.role = nil }
    it { should be_valid }
  end

  describe 'enforce nil values' do
    before { example.bin = nil }
    it { should be_invalid }
  end

  describe 'string conversions' do
    it 'should convert a string value into a symbol' do
      example.bin = 'hungry'
      expect(example.bin).to eq :hungry
    end
  end

  describe 'valid values' do
    it 'should handle arrays' do
      example.grades = [:a, :b]
      expect(example).to be_valid
    end
  end

  describe 'invalid values' do
    context 'Symbols' do
      before { example.bin = :i_dont_exist }
      it { should be_invalid }
    end

    context 'Arrays' do
      before { example.grades = [:a, :z] }
      it { should be_invalid }
    end
  end

  describe 'deltas method' do
    it 'should show removed and added' do
      example.grades = [:a, :b, :c]
      example.save
      example.grades = [:c, :d, :e]
      expect(example.grades_deltas[:added]).to eq [:d, :e]
      expect(example.grades_deltas[:removed]).to eq [:a, :b]
    end
  end

  describe 'is_? methods' do
    its(:admin?) { should be true }
    its(:standard?) { should be false }

    its(:is_hungry_bin?) { should be true }
    its(:is_bored_bin?) { should be false }

    context 'array enums' do
      before { example.grades = [:a, :c] }
      its(:is_a_grade?) { should be true }
      its(:is_b_grade?) { should be false }
      its(:is_c_grade?) { should be true }
    end
  end

  describe 'values' do
    it '#bin_value' do
      expect(EnumExample.bin_values).to eq [:hungry, :bored]
    end
  end
end
