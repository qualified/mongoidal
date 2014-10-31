require 'spec_helper'
require 'sidekiq'

describe Mongoidal::Service do
  let(:service) { Mongoidal::Service.new }

  describe '#worker_args' do
    subject { service.send(:worker_args, *args) }

    shared_examples 'packed current_user_id' do
      let(:current_user) { User.current }

      it 'should have current_user_id if one is present' do
        subject['current_user_id'].should == current_user.id.to_s
      end

      it 'should not have current_user_id if one is present' do
        subject['current_user_id'].should be_nil
      end
    end

    shared_examples 'root document as first argument' do
      it 'should have a hash as its only value' do
        params.first.should be_a Hash
      end

      it 'should have a "_" root_doc value' do
        params.first['_'].should == 'root_doc'
      end

      it 'should have a class_name' do
        params.first['class_name'].should == root_document.class.name
      end

      it 'should have an id' do
        params.first['id'].should == root_document.id.to_s
      end
    end

    context '(id)' do
      let(:root_document) { User.new }
      let(:args) { [root_document.id] }

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have one value' do
          params.count.should == 1
        end

        it 'should be a string version of the id' do
          params.first.should == root_document.id.to_s
        end
      end

    end

    context '(root_document)' do
      let(:root_document) { User.new }
      let(:args) { [root_document] }

      it_behaves_like 'packed current_user_id'

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have one value' do
          params.count.should == 1
        end

        include_examples 'root document as first argument'
      end
    end

    context '(root_document, int)' do
      let(:root_document) { User.new }
      let(:args) { [root_document, 5] }

      it_behaves_like 'packed current_user_id'

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have two values' do
          params.count.should == 2
        end

        it_behaves_like 'root document as first argument'

        it 'should have an int as 2nd argument' do
          params[1].should == 5
        end
      end
    end

    context '(root_document, embedded_document)' do
      let(:root_document) { User.new }
      let(:args) { [root_document, root_document.languages.first] }

      it_behaves_like 'packed current_user_id'

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have two values' do
          params.count.should == 2
        end

        it_behaves_like 'root document as first argument'

        context 'embedded document as 2nd argument' do
          let(:param) { params[1] }

          it 'should have a "_" embedded_doc value' do
            param['_'].should == 'embedded_doc'
          end

          it 'should have a class_name' do
            param['class_name'].should == args[1].class.name
          end

          it 'should have an id' do
            param['id'].should == args[1].id.to_s
          end

          it 'should have a parent id' do
            param['parent_id'].should == args[0].id.to_s
          end

          it 'should have a parent class' do
            param['parent_class_name'].should == args[0].class.name
          end
        end

      end
    end
  end
end