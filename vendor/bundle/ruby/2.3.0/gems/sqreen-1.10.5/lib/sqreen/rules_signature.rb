# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'sqreen/exception'

require 'set'
require 'openssl'
require 'base64'
require 'json'
if defined?(::JRUBY_VERSION)
  OJ_LOADED = false
else
  begin
    require "oj"
    OJ_LOADED = true
  rescue LoadError
    OJ_LOADED = false
  end
end

## Rules signature
module Sqreen
  # Perform an EC + digest verification of a message.
  class SignatureVerifier
    def initialize(key, digest)
      @pub_key              = OpenSSL::PKey.read(key)
      @digest               = digest
    end

    def verify(sig, val)
      hashed_val = @digest.digest(val)
      @pub_key.dsa_verify_asn1(hashed_val, sig)
    end
  end

  # Normalize and verify a rule
  class SqreenSignedVerifier
    REQUIRED_SIGNED_KEYS = %w[hookpoint name callbacks conditions].freeze
    SIGNATURE_KEY        = 'signature'.freeze
    SIGNATURE_VALUE_KEY  = 'value'.freeze
    SIGNED_KEYS_KEY      = 'keys'.freeze
    SIGNATURE_VERSION    = 'v0_9'.freeze
    PUBLIC_KEY           = <<-END.gsub(/^ */, '').freeze
    -----BEGIN PUBLIC KEY-----
    MIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQA39oWMHR8sxb9LRaM5evZ7mw03iwJ
    WNHuDeGqgPo1HmvuMfLnAyVLwaMXpGPuvbqhC1U65PG90bTJLpvNokQf0VMA5Tpi
    m+NXwl7bjqa03vO/HErLbq3zBRysrZnC4OhJOF1jazkAg0psQOea2r5HcMcPHgMK
    fnWXiKWnZX+uOWPuerE=
    -----END PUBLIC KEY-----
    END

    attr_accessor :pub_key
    attr_accessor :required_signed_keys
    attr_accessor :digest
    attr_accessor :use_oj

    def initialize(required_keys = REQUIRED_SIGNED_KEYS,
                   public_key    = PUBLIC_KEY,
                   digest        = OpenSSL::Digest::SHA512.new, use_oj_gem = nil)
      @required_signed_keys = required_keys
      @signature_verifier   = SignatureVerifier.new(public_key, digest)
      @use_oj = use_oj_gem.nil? ? OJ_LOADED : use_oj_gem
    end

    def normalize_val(val, level)
      raise Sqreen::Exception, 'recursion level too deep' if level == 0

      case val
      when Hash
        normalize(val, nil, level - 1)
      when Array
        ary = val.map do |i|
          normalize_val(i, level - 1)
        end
        "[#{ary.join(',')}]"
      when String, Integer
        return Oj.dump(val, :mode => :compat, :escape_mode => :json) if use_oj
        begin
          JSON.dump(val)
        rescue JSON::GeneratorError
          JSON.generate(val, :quirks_mode => true)
        end
      else
        msg = "JSON hash parsing error (wrong value type: #{val.class})"
        raise Sqreen::Exception.new, msg
      end
    end

    def normalize_key(key)
      case key
      when String, Integer
        return Oj.dump(key, :mode => :compat, :escape_mode => :json) if use_oj
        begin
          JSON.dump(key)
        rescue JSON::GeneratorError
          JSON.generate(key, :quirks_mode => true)
        end
      else
        msg = "JSON hash parsing error (wrong key type: #{key.class})"
        raise Sqreen::Exception, msg
      end
    end

    def normalize(hash_rule, signed_keys = nil, level = 20)
      # Normalize the provided hash to a string:
      #  - sort keys lexicographically, recursively
      #  - convert each scalar to its JSON representation
      #  - convert hash to '{key:value}'
      #  - convert array [v1,v2] to '[v1,v2]' and [] to '[]'
      # Two hash with different key ordering should have the same normalized
      # value.

      raise Sqreen::Exception, 'recursion level too deep' if level == 0
      unless hash_rule.is_a?(Hash)
        raise Sqreen::Exception, "wrong hash type #{hash_rule.class}"
      end

      res = []
      hash_rule.sort.each do |k, v|
        # Only keep signed keys
        next if signed_keys && !signed_keys.include?(k)

        k = normalize_key(k)
        v = normalize_val(v, level - 1)

        res << "#{k}:#{v}"
      end
      "{#{res.join(',')}}"
    end

    def get_sig_infos_or_fail(hash_rule)
      raise Sqreen::Exception, 'non hash argument' unless hash_rule.is_a?(Hash)

      sigs = hash_rule[SIGNATURE_KEY]
      raise Sqreen::Exception, 'no signature found' unless sigs

      sig = sigs[SIGNATURE_VERSION]
      msg = "signature #{SIGNATURE_VERSION} not found (#{sigs})"
      raise Sqreen::Exception, msg unless sig

      sig_value = sig[SIGNATURE_VALUE_KEY]
      raise Sqreen::Exception, 'no signature value found' unless sig_value

      signed_keys = sig[SIGNED_KEYS_KEY]
      raise Sqreen::Exception, "no signed keys found (#{sig})" unless signed_keys

      inc = Set.new(signed_keys).superset?(Set.new(@required_signed_keys))
      raise Sqreen::Exception, 'signed keys miss equired keys' unless inc

      [signed_keys, sig_value]
    end

    def verify(hash_rule)
      # Return true if rule signature is correct, else false

      signed_keys, sig_value = get_sig_infos_or_fail(hash_rule)

      norm_str = normalize(hash_rule, signed_keys)
      bin_sig = Base64.decode64(sig_value)
      @signature_verifier.verify(bin_sig, norm_str)
    rescue OpenSSL::PKey::ECError
      false
    end
  end
end
