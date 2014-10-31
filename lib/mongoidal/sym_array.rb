module Mongoidal
  class SymArray < Array

    def mongoize(object)
      super object
    end

    class << self
      def demongoize(array)
        array.nil? ? nil : array.map {|v| v.respond_to?(:to_sym) ? v.to_sym : v}
      end

      def evolve(object)
        Array.evolve(object)
      end
    end

  end
end