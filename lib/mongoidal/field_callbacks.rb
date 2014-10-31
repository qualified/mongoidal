module Mongoidal
  module FieldCallbacks
    extend ActiveSupport::Concern

    def fields_before_save
      @fields_before_save ||= []
    end

    def fields_after_save
      @fields_after_save ||= []
    end

    module ClassMethods
      def before_field_save(field, method = nil, &block)
        around_save do |model, do_save|
          unless model.fields_before_save.include? field
            if model.__send__ "#{field}_changed?"
              model.fields_before_save << field
              if method
                model.__send__(method)
              else
                model.instance_exec(model, (model.__send__ "#{field}_change"), &block)
              end
              do_save.call
              model.fields_before_save.delete(field)
            else
              do_save.call
            end
          end
        end

      end

      def after_field_save(field, method = nil, &block)
        around_save do |model, do_save|
          unless model.fields_after_save.include? field
            if model.__send__ "#{field}_changed?"
              model.fields_after_save << field
              do_save.call
              if method
                model.__send__(method)
              else
                block.call(model, (model.__send__ "#{field}_change"))
              end
              model.fields_after_save.delete(field)
            else
              do_save.call
            end
          end
        end

      end
    end
  end
end