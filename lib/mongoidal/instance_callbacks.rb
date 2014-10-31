module Mongoidal
  # provides the ability to assign CRUD callbacks to individual instances. All callbacks are a one
  # time use and then get cleared.
  module InstanceCallbacks
    extend ActiveSupport::Concern

    included do
      after_create do |d|
        d.run_dynamic_callbacks(:after_create)
      end

      after_update do |d|
        d.run_dynamic_callbacks(:after_update)
      end

      after_save do |d|
        d.run_dynamic_callbacks(:after_save)
      end

      after_destroy do |d|
        d.run_dynamic_callbacks(:after_destroy)
      end
    end

    def dynamic_callbacks
      @dynamic_callbacks ||= { after_save: [], after_create: [], after_update: [], after_destroy: []}
    end

    # macro that only calls the block now if the record already exists and
    # after the record is created if it is a currently new record
    def when_created(&block)
      if self.new_record?
        after_create(&block)
      else
        block.call(self)
      end
    end

    def after_create(&block)
      dynamic_callbacks[:after_create] << block
    end

    def after_update(&block)
      dynamic_callbacks[:after_update] << block
    end

    def after_save(&block)
      dynamic_callbacks[:after_save] << block
    end

    def after_destroy(&block)
      dynamic_callbacks[:after_destroy] << block
    end

    protected

    def run_dynamic_callbacks(key)
      # cache them now
      callbacks = dynamic_callbacks[key]

      # so that we can reset them before calling them. This allows the callbacks
      # to refire additional callbacks without getting into an infinite loop
      dynamic_callbacks[key] = []

      callbacks.each do |cb|
        cb.call(self)
      end
    end
  end
end