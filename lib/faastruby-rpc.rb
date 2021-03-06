require 'net/http'
require 'oj'
require 'yaml'
require 'openssl'
require 'faastruby-rpc/version'
require 'faastruby-rpc/caller'
require 'faastruby-rpc/function'

(Net::HTTP::SSL_IVNAMES << :@ssl_options).uniq!
(Net::HTTP::SSL_ATTRIBUTES << :options).uniq!

Net::HTTP.class_eval do
  attr_accessor :ssl_options
end

def require_function(function, as:, raise_errors: true)
  as[0] = as[0].capitalize
  Object.send(:remove_const, as) if Object.const_defined?(as)
  Object.const_set as, FaaStRuby::RPC::Caller.new(function, raise_errors: raise_errors)
  return false
end
