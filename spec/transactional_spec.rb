require 'spec_helper'

class TransactionExample
  include Mongoid::Document
  include Mongoidal::Transactional
  field :label
  validates :label, presence: true

end

describe Mongoidal::Transactional do
  let(:t1) { TransactionExample.new(label: 'good') }
  let(:t2) { TransactionExample.new }

  it 'should not save until after the transaction has completed' do
    Mongoidal.transaction do
      t1.save!
      expect(t1).to be_new_record
    end

    expect(t1).to_not be_new_record
  end

  it 'should support arbitray actions' do
    name = nil
    Mongoidal.transaction do |transaction|
      t1.save!
      transaction.add do
        name = "good"
      end
      expect(name).to be_nil
    end

    expect(name).to eq "good"
  end

  it 'should not save if there is a failure' do
    begin
      Mongoidal.transaction do
        t1.save!
        t2.save!
      end
    rescue
      expect(t1).to be_new_record
    end
  end

  it 'should support nested transactions' do
    begin
      Mongoidal.transaction do
        t1.save!
        Mongoidal.transaction do
          t2.save!
        end
      end
    rescue
      expect(t1).to be_new_record
    end
  end

  it 'should support nested transactions with ability to commit nested' do
    begin
      Mongoidal.transaction do
        Mongoidal.transaction do |t|
          t1.save!
          t.commit!
        end
        t2.save!
      end
    rescue
      expect(t1).to_not be_new_record
    end
  end
end