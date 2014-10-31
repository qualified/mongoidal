require 'spec_helper'

class ExampleWorker
  include Mongoidal::ServiceObjectWorker

  def execute
  end
end

describe Mongoidal::ServiceObjectWorker do
  let(:worker) { ExampleWorker.new }
  before { allow(worker).to receive(:execute) }

  def pack_args(*args)
    Mongoidal::ServiceObject.new.send(:worker_args, *args)
  end

  describe '#current_user' do
    context 'when current_user_id is provided and perform is called' do
      let(:user) { User.create }
      let(:options) { pack_args }
      before do
        user.make_current do
          options
        end
      end

      it 'should set user to current' do
        worker.perform(options)
        expect {worker.current_user}.to change { User.current }.to(user)
      end

      it 'should set current_user' do
        expect {worker.perform(options)}.to change { worker.current_user }.to(user)
      end
    end
  end

  describe '#unpack_params' do
    def pack_params(*params)
      Mongoidal::ServiceObject.new.send(:pack_params, params)
    end

    let(:root_document) { RevisableExample.create }
    let(:embed_document) { root_document.revisable_embedded_examples.create }

    subject { worker.send(:unpack_params, params) }

    context 'expanding a root document' do
      let(:params) { pack_params(root_document) }

      it 'should return the root document' do
        expect(subject.first).to eq root_document
      end
    end

    context 'expanding an embedded document' do
      let(:params) { pack_params(embed_document) }

      it 'should return the root document' do
        expect(subject.first).to eq embed_document
      end
    end

    context 'expanding multiple documents' do
      let(:args) { [root_document, embed_document, 'a', 1] }
      let(:params) { pack_params(*args) }

      it 'should expand into original values' do
        expect(subject).to eq(args)
      end
    end

    context 'expanding a class' do
      let(:params) { pack_params(RevisableExample) }

      it 'should epxand into class' do
        expect(subject.first).to eq(RevisableExample)
      end
    end
  end
end