require 'net/http'
require 'oj'
require 'yaml'
require 'faastruby-rpc/version'
require 'faastruby-rpc/function'

def invoke(function, raise_errors: true)
  FaaStRuby::RPC::Function.new(function, raise_errors: raise_errors)
end
