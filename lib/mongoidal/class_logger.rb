module Mongoidal
  module ClassLogger
    def logger
      @logger ||= ClassLogger::Logger.new(self)
    end

    def logger_name
      if respond_to? :name
        name
      else
        '[No Name]'
      end
    end

    class Logger
      def initialize(instance)
        @instance = instance
      end

      def method_missing(method, *args)
        args[0] = format(args[0]) if args.any?
        Rails.logger.send method, *args
      end

      def id
        if @instance.respond_to? :id
          "[#{@instance.id}] - "
        end
      end

      def format(msg)
        "#{@instance.class.name} #{id}#{@instance.logger_name}: #{msg}"
      end
    end
  end
end