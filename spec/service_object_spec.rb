require 'spec_helper'
require 'sidekiq'

describe Mongoidal::ServiceObject do
  let(:service) { Mongoidal::ServiceObject.new }

  describe '#worker_args' do
    subject { service.send(:worker_args, *args) }

    shared_examples 'packed current_user_id' do

      it 'should have current_user_id if one is present' do
        User.create.make_current
        expect(subject['current_user_id']).to eq(User.current.id.to_s)
      end

      it 'should not have current_user_id if one is present' do
        expect(subject['current_user_id']).to be_nil
      end
    end

    shared_examples 'root document as first argument' do
      it 'should have a hash as its only value' do
        expect(params.first).to be_a Hash
      end

      it 'should have a "_" root_doc value' do
        expect(params.first['_']).to eq('root_doc')
      end

      it 'should have a class_name' do
        expect(params.first['class_name']).to eq(root_document.class.name)
      end

      it 'should have an id' do
        expect(params.first['id']).to eq(root_document.id.to_s)
      end
    end

    context '(id)' do
      let(:root_document) { RevisableExample.create }
      let(:args) { [root_document.id] }

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have one value' do
          expect(params.count).to eq(1)
        end

        it 'should be a string version of the id' do
          expect(params.first).to eq(root_document.id.to_s)
        end
      end

    end

    context '(root_document)' do
      let(:root_document) { RevisableExample.create }
      let(:args) { [root_document] }

      it_behaves_like 'packed current_user_id'

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have one value' do
          expect(params.count).to eq(1)
        end

        include_examples 'root document as first argument'
      end
    end

    context '(root_document, int)' do
      let(:root_document) { RevisableExample.create }
      let(:args) { [root_document, 5] }

      it_behaves_like 'packed current_user_id'

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have two values' do
          expect(params.count).to eq(2)
        end

        it_behaves_like 'root document as first argument'

        it 'should have an int as 2nd argument' do
          expect(params[1]).to eq(5)
        end
      end
    end

    context '(root_document, embedded_document)' do
      let(:root_document) { RevisableExample.create }
      let(:embedd) { root_document.revisable_embedded_examples.create }
      let(:args) { [root_document, embedd] }

      it_behaves_like 'packed current_user_id'

      context 'params array' do
        let(:params) { subject['params'] }

        it 'should have two values' do
          expect(params.count).to eq(2)
        end

        it_behaves_like 'root document as first argument'

        context 'embedded document as 2nd argument' do
          let(:param) { params[1] }

          it 'should have a "_" embedded_doc value' do
            expect(param['_']).to eq('embedded_doc')
          end

          it 'should have a class_name' do
            expect(param['class_name']).to eq(args[1].class.name)
          end

          it 'should have an id' do
            expect(param['id']).to eq(args[1].id.to_s)
          end

          it 'should have a parent id' do
            expect(param['parent_id']).to eq(args[0].id.to_s)
          end

          it 'should have a parent class' do
            expect(param['parent_class_name']).to eq(args[0].class.name)
          end
        end

      end
    end
  end
end