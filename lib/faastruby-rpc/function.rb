module FaaStRuby
  FAASTRUBY_HOST = ENV['FAASTRUBY_HOST'] || "http://localhost:3000"
  module RPC
    class ExecutionError < StandardError
    end
    class Response
      attr_reader :body, :code, :headers, :klass
      def initialize(body, code, headers, klass = nil)
        @body = body
        @code = code
        @headers = headers
        @klass = klass
      end
      def body=(value)
        @body = value
      end
    end
    class Function
      def initialize(path, raise_errors: true)
        @response = nil
        @path = path
        @methods = {
          'post' => Net::HTTP::Post,
          'get' => Net::HTTP::Get,
          'put' => Net::HTTP::Put,
          'patch' => Net::HTTP::Patch,
          'delete' => Net::HTTP::Delete
        }
        @raise_errors = raise_errors
      end

      def call(*args)
        @thread = Thread.new do
          output = args.any? ? call_with(*args) : execute(method: 'get')
          @response.body = yield(output) if block_given?
        end
        self
      end

      def execute(req_body: nil, query_params: {}, headers: {}, method: 'post')
        url = "#{FAASTRUBY_HOST}/#{@path}#{convert_query_params(query_params)}"
        uri = URI.parse(url)
        use_ssl = uri.scheme == 'https' ? true : false
        function_response = fetch(use_ssl: use_ssl, uri: uri, headers: headers, method: @methods[method], req_body: req_body)
        resp_headers = {}
        function_response.each{|k,v| resp_headers[k] = v}
        case resp_headers['content-type']
        when 'application/json'
          begin
            resp_body = Oj.load(function_response.body)
          rescue Oj::ParseError => e
            if function_response.body.is_a?(String)
              resp_body = function_response.body
            else
              raise e if @raise_errors
              resp_body = {
                'error' => e.message,
                'location' => e.backtrace&.first
              }
            end
          end
        when 'application/yaml'
          resp_body = YAML.load(function_response.body)
        else
          resp_body = function_response.body
        end
        if function_response.code.to_i >= 400 && @raise_errors
          location = resp_body['location'] ? " @ #{resp_body['location']}" : nil
          error_msg = "#{resp_body['error']}#{location}"
          raise FaaStRuby::RPC::ExecutionError.new("Function #{@path} returned status code #{function_response.code}: #{error_msg}")
        end
        @response = FaaStRuby::RPC::Response.new(resp_body, function_response.code.to_i, resp_headers)
        self
      end

      def returned?
        !@response.nil?
      end

      def response
        wait unless returned?
        @response
      end

      def to_s
        body.to_s || ""
      end

      def body
        # wait unless returned?
        response.body
      end

      def code
        # wait unless returned?
        response.code
      end

      def headers
        # wait unless returned?
        response.headers
      end

      def klass
        # wait unless returned?
        response.klass
      end

      private

      def call_with(*args)
        execute(req_body: Oj.dump(args), headers: {'Content-Type' => 'application/json', 'Faastruby-Rpc' => 'true'})
      end

      def wait
        @thread.join
      end

      def convert_query_params(query_params)
        return "" unless query_params.any?
        "?#{URI.encode_www_form(query_params)}"
      end

      def fetch(use_ssl:, uri:, limit: 10, method: Net::HTTP::Post, headers: {}, req_body: nil)
        # You should choose a better exception.
        raise ArgumentError, 'too many HTTP redirects' if limit == 0
        http = Net::HTTP.new(uri.host, uri.port)
        if use_ssl
          http.use_ssl = true
          http.ssl_options = OpenSSL::SSL::OP_NO_SSLv2 + OpenSSL::SSL::OP_NO_SSLv3 + OpenSSL::SSL::OP_NO_COMPRESSION
        end
        request = method.new(uri.request_uri, headers)
        request.body = req_body
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
