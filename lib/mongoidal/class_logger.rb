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

    protected

    # easy way to log the return value of code
    def log_info(result = nil)
      result ||= yield
      logger.debug "#{caller_locations(1,1)[0].label}: #{result.inspect}"
      result
    end

    # easy way to log the return value of code
    def log_info(result = nil)
      result ||= yield
      logger.info "#{caller_locations(1,1)[0].label}: #{result.inspect}"
      result
    end

    class Logger
      def initialize(instance)
        @instance = instance
      end

      def method_missing(method, *args, &block)
        args[0] = format(args[0])
        if block_given?
          Rails.logger.send method do
            format(block.call)
          end
        else
          Rails.logger.send method, *args
        end
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