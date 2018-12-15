require 'faastruby-rpc'
module FaaStRuby
  module RPC
    class TestHelper
      attr_accessor :body, :code, :headers, :klass
      def initialize
        @body = nil
        @code = 200
        @headers = {}
        @klass = nil
      end
    end
  end
end
