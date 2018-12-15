module FaaStRuby
  FAASTRUBY_HOST = ENV['FAASTRUBY_HOST'] || "http://localhost:3000"
  module RPC
    @@response = {}
    def self.stub_call(function_path, &block)
      helper = TestHelper.new
      block.call(helper)
      response = Struct.new(:body, :code, :headers, :klass)
      @@response[function_path] = response.new(helper.body, helper.code, helper.headers, helper.klass)
    end
    def self.stub_call?(path)
      @@response[path]
    end

    def self.response(path)
      @@response[path]
    end

    class ExecutionError < StandardError
    end
    class Function
      def initialize(path, raise_errors: true)
        @path = path
        @methods = {
          'post' => Net::HTTP::Post,
          'get' => Net::HTTP::Get,
          'put' => Net::HTTP::Put,
          'patch' => Net::HTTP::Patch,
          'delete' => Net::HTTP::Delete
        }
        @response = Struct.new(:body, :code, :headers, :klass)
        @raise_errors = raise_errors
      end
      def with(*args)
        call(body: Oj.dump(args), headers: {'Content-Type' => 'application/json', 'Faastruby-Rpc' => 'true'})
      end

      def call(body: nil, query_params: {}, headers: {}, method: 'post')
        url = "#{FAASTRUBY_HOST}/#{@path}#{convert_query_params(query_params)}"
        uri = URI.parse(url)
        use_ssl = uri.scheme == 'https' ? true : false
        response = FaaStRuby::RPC.stub_call?(@path) ? FaaStRuby::RPC.response(@path) : fetch(use_ssl: use_ssl, uri: uri, headers: headers, method: @methods[method], body: body)
        resp_headers = {}
        response.each{|k,v| resp_headers[k] = v}
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
        @response.new(resp_body, response.code.to_i, resp_headers)
      end

      private
      def convert_query_params(query_params)
        return "" unless query_params.any?
        "?#{URI.encode_www_form(query_params)}"
      end

      def fetch(use_ssl:, uri:, limit: 10, method: Net::HTTP::Post, headers: {}, body: nil)
        # You should choose a better exception.
        raise ArgumentError, 'too many HTTP redirects' if limit == 0
        http = Net::HTTP.new(uri.host, uri.port)
        if use_ssl
          http.use_ssl = true
          http.ssl_options = OpenSSL::SSL::OP_NO_SSLv2 + OpenSSL::SSL::OP_NO_SSLv3 + OpenSSL::SSL::OP_NO_COMPRESSION
        end
        request = method.new(uri.request_uri, headers)
        request.body = body
        response = http.request(request)

        case response
        when Net::HTTPSuccess then
          response
        when Net::HTTPRedirection then
          location = URI.parse(response['location'])
          warn "redirected to #{location}"
          fetch(use_ssl: use_ssl, uri: location, limit: limit - 1, method: method, headers: headers, body: body)
        else
          response.value
        end

      rescue Net::HTTPServerException, Net::HTTPFatalError
        return response
      end
    end
  end
end
