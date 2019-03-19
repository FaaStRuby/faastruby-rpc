module FaaStRuby
  module RPC
    class Caller
      def initialize(path, raise_errors: true)
        @path = path
        @raise_errors = raise_errors
      end

      def call(*args)
        function = FaaStRuby::RPC::Function.new(@path, raise_errors: @raise_errors)
        function.call(*args)
      end
    end
  end
end
