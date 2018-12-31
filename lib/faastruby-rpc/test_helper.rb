require 'faastruby-rpc'
module FaaStRuby
  module RPC
    @@response = {}
    def self.stub_call(function_path, &block)
      helper = TestHelper.new
      block.call(helper)
      @@response[function_path] = FaaStRuby::RPC::Response.new(helper.body, helper.code, helper.headers, helper.klass)
    end
    def self.stub_call?(path)
      @@response[path]
    end

    def self.response(path)
      @@response[path]
    end
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

FaaStRuby::RPC::Function.class_eval do
  def execute(req_body: nil, query_params: {}, headers: {}, method: 'post')
    @thread = Thread.new do
      url = "#{FAASTRUBY_HOST}/#{@path}#{convert_query_params(query_params)}"
      uri = URI.parse(url)
      use_ssl = uri.scheme == 'https' ? true : false
      response = FaaStRuby::RPC.response(@path)
      resp_headers = {}
      response.headers.each{|k,v| resp_headers[k] = v}
      case resp_headers['content-type']
      when 'application/json'
        begin
          resp_body = Oj.load(response.body)
        rescue Oj::ParseError => e
          if response.body.is_a?(String)
            resp_body = response.body
          else
            raise e if @raise_errors
            resp_body = {
              'error' => e.message,
              'location' => e.backtrace&.first
            }
          end
        end
      when 'application/yaml'
        resp_body = YAML.load(response.body)
      else
        resp_body = response.body
      end
      raise FaaStRuby::RPC::ExecutionError.new("Function #{@path} returned status code #{response.code} - #{resp_body['error']} - #{resp_body['location']}") if response.code.to_i >= 400 && @raise_errors
      @response = FaaStRuby::RPC::Response.new(resp_body, response.code.to_i, resp_headers)
    end
    self
  end
end
