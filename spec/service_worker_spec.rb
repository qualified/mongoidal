require 'spec_helper'


describe Mongoidal::ServiceWorker do
  let(:worker) { Mongoidal::ServiceWorker.new }
  before { worker.stub(:execute) }

  def pack_args(*args)
    Mongoidal::Service.new.send(:worker_args, *args)
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
      Mongoidal::Service.new.send(:pack_params, params)
    end

    let(:root_document) { RootExample.create }

    subject { worker.send(:unpack_params, params) }

    context 'expanding a root document' do
      let(:params) { pack_params(root_document) }

      it 'should return the root document' do
        subject.first.should be root_document
      end
    end

    context 'expanding an embedded document' do
      let(:params) { pack_params(root_document.languages.first) }

      it 'should return the root document' do
        subject.first.should be root_document.languages.first
      end
    end

    context 'expanding multiple documents' do
      let(:args) { [root_document, root_document.languages.first, 'a', 1] }
      let(:params) { pack_params(*args) }

      it 'should expand into original values' do
        subject.should == args
      end
    end

    context 'expanding a class' do
      let(:params) { pack_params(RootExample) }

      it 'should epxand into class' do
        subject.first.should == RootExample
      end
    end
  end
end