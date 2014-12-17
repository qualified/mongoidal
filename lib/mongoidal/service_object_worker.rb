require 'sidekiq'

module Mongoidal
  module ServiceObjectWorker
    extend ActiveSupport::Concern

    included do
      include Sidekiq::Worker
      include ClassLogger
    end

    def job_name(*args)
      logger_name
    end

    # returns the current_user, who was the user set as current at the time that
    # this worker was originally queued.
    def current_user
      @current_user ||= load_current_user
    end

    # will load and return the current user that was current at the time that the context worker
    # was queued. This will also make that user the User.current
    def load_current_user
      @current_user = if @args && @args['current_user_id']
        User.current = User.find(@args['current_user_id'])
      end
    end

    def perform(args)
      @args = args
      execute(*unpack_params(args['params']))
    end

    protected

    # complex objects are passed in using a "packed" format, which is basically just a way
    # of passing the minimal information to reproduce the complex object. Currently only mongoid
    # documents are supported. Their class names and ids are passed in so that they can be retrieved.
    def unpack_params(params)
      params.map do |param|
        if param.is_a?(Hash) and param.has_key?('_')
          unpack_param(param)
        else
          param
        end
      end
    end

    def unpack_param(param)
      value = case param['_']
        when 'root_doc'
          param['class_name'].to_const.where(id: param['id']).first

        when 'embedded_doc'
          expand_embedded_doc(param)

        when 'class'
          param['class_name'].to_const

        else
          param
      end

      logger.warn "unable to find #{param}" unless value
      value
    end

    # uses the path info passed in as a way of recovering the embedded document
    def expand_embedded_doc(param)
      parent = param['parent_class_name'].to_const.where(id: param['parent_id']).first
      if parent
        parent.relations.values.each do |relation|
          if relation.class_name == param['class_name']
            return parent.send(relation.name).where(id: param['id']).first
          end
        end
      end
      nil
    end
  end
end