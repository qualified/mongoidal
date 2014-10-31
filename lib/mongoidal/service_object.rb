module Mongoidal
  # provides a base service class to use for creating advanced operations on data models.
  class ServiceObject
    include ClassLogger

    def current_user
      User.current
    end

    def executed?
      @executed ||= false
    end

    # executes the context. Inheriting classes should implement a on_execute method.
    def execute(*args)
      if executed?
        logger.warn 'execute skipped, already called once'

      else
        @executed = true
        start = Time.now
        logger.debug 'executing...'
        on_execute(*args)
        logger.debug "executed - took #{Time.now - start} seconds to complete"
      end

      self
    end

    protected

    # override in implementing classes to provide custom additional arguments to the worker
    def custom_args
      {}
    end

    def worker_args(*args)
      args = {'params' => pack_params(args)}
      if User.respond_to?(:current)
        args['current_user_id'] = User.current && User.current.id.to_s
      end
      args.merge!(custom_args)
    end

    # packs up the params so that they can go on a trip! Basically it stores the information needed
    # to find the models within the database, once they are unpacked by the worker.
    def pack_params(args)
      args.map do |arg|
        if arg.is_a? Mongoid::Document
          if arg.is_a? Mongoidal::EmbeddedDocument
            worker_embedded_document_params(arg)
          else
            worker_document_params(arg)
          end
        elsif arg.is_a? BSON::ObjectId
          arg.to_s
        elsif arg.is_a? Class
          { '_' => 'class', 'class_name' => arg.name }
        else
          arg
        end
      end
    end

    def worker_document_params(doc)
      {'_' => 'root_doc',
       'class_name' => doc.class.name,
       'id' => doc.id.to_s
      }
    end

    def worker_embedded_document_params(doc)
      raise WorkerError.new(self, 'Parent is missing') unless doc.parent_model
      raise WorkerError.new(self, 'Parent is not saved') if doc.parent_model.new_record?
      # we can only currently support embedded documents one level deep
      raise WorkerError.new(self, 'Nested too deep') if doc.parent_model.is_a?(Mongoidal::EmbeddedDocument)

      {'_' => 'embedded_doc',
       'parent_class_name' => doc.parent_relationship.class_name,
       'parent_id' => doc.parent_model.id.to_s,
       'class_name' => doc.class.name,
       'id' => doc.id.to_s
      }
    end

    class WorkerError < StandardError
      def initialize(ref, msg)
        type, name = ref.is_a?(Class) ? ["Class", ref.name] : ["Instance", ref.class.name]
        super("#{name} #{type} cannot be executed in background: #{msg}")
      end
    end

  end
end