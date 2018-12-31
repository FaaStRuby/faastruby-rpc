require 'net/http'
require 'oj'
require 'yaml'
require 'openssl'
require 'faastruby-rpc/version'
require 'faastruby-rpc/function'

(Net::HTTP::SSL_IVNAMES << :@ssl_options).uniq!
(Net::HTTP::SSL_ATTRIBUTES << :options).uniq!

Net::HTTP.class_eval do
  attr_accessor :ssl_options
end

def invoke(function, raise_errors: true)
  function(function, raise_errors: raise_errors)
end

def function(function, raise_errors: true)
  FaaStRuby::RPC::Function.new(function, raise_errors: raise_errors)
end

def require_function(function, as:, raise_errors: true)
  Object.send(:remove_const, as.capitalize) if Object.const_defined?(as.capitalize)
  Object.const_set as.capitalize, FaaStRuby::RPC::Function.new(function, raise_errors: raise_errors)
  return false
end
