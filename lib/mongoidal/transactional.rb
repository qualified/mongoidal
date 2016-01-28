module Mongoidal
  def self.transaction(&block)
    Transactional.new(&block)
  end

  # Psuedu transaction support for Mongoid. These are basic client-only transactions where all
  # actual save operations are batched and commited at once. This allows you to save multiple objects
  # in sequence without having to first check that they are all valid.
  # Transactions will only fail if any of the records are invalid.
  # You must use save! method in order for the save operations to be registered with the
  # transaction.
  module Transactional
    extend ActiveSupport::Concern

    included do
      def save!
        Transactional.add(self) { super }
      end
    end

    def self.add(model, &block)
      transaction = Transactional.current
      if transaction
        transaction.add(model, &block)
      else
        block.call
      end
    end

    def self.current
      Thread.current[:transactional_current]
    end

    def self.new(&block)
      raise "Transation block required" unless block_given?
      t = Transaction.new(current)
      Thread.current[:transactional_current] = t
      begin
        block.call(t)
        Thread.current[:transactional_current] = t.parent
        t.commit! unless t.parent
      rescue
        Rails.logger.warn 'Exception raised, aborting current transaction'
        Thread.current[:transactional_current] = nil
        raise
      end
    end

    class Transaction
      attr_reader :parent

      def initialize(parent = nil)
        @actions = []
        @after = {commit: [], abort: []}
        @children = []
        if parent
          @parent = parent
          parent.add_child(self)
        end
      end

      def add_child(child)
        @children << child
      end

      def add(target = nil, &block)
        raise "Transaction has already been commited" if commited?
        if @commiting
          block.call
        else
          @actions << [target, block]
        end
      end

      # called after transaction is commited
      def after_commit(&block)
        @after[:commit] << block
      end

      # called after transaction is aborted
      def after_abort(&block)
        @after[:abort] << block
      end

      def validate!
        unless @valid or @aborted
          # first go through and find any models that are invalid. Calling the block on them should raise an
          # error
          @actions.each do |target, block|
            if target and target.respond_to?(:invalid?)
              block.call if target.invalid?
            end
          end
          @valid = true
        end
      end

      def commited?
        @commited
      end

      def commit!
        return false if commited? or @commiting or @aborted
        @commiting = true

        @children.each(&:validate!)
        validate!

        @children.each(&:commit!)

        # if no blocks were called (no errors raised) then lets loop back through and call the block on everything
        @actions.each do |model, block|
          block.call
        end
        @commiting = false
        begin
          @after[:commit].each(&:call)
        ensure
          @commited = true
        end
      end

      def abort!
        raise "Cannot abort an already commited transaction" if commited?
        begin
          @after[:abort].each(&:call)
        ensure
          @aborted = true
        end
      end
    end
  end
end
