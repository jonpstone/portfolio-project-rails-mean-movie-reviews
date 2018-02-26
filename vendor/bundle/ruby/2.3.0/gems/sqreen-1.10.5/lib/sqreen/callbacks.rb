# Copyright (c) 2015 Sqreen. All Rights Reserved.
# Please refer to our terms for more information: https://www.sqreen.io/terms.html

require 'set'
require 'sqreen/shared_storage'

module Sqreen

  class CB
    # Callback class.
    #
    # Three methods can be defined:
    # - pre(*args, &block)
    #   To be called prior to the hooked method.
    # - post(return_value, *args, &block)
    #   To be called after the hooked method. The return_value argument is
    #   the value returned by the hooked method.
    # - failing(exception, ...)
    #   To be called when the method raise
    # The method pre, post and exception may return nil or a Hash.
    #  - nil: the original method is called and the callback has no further
    #    effect
    #  - { :status => :skip }: we skip the original method call
    #  - { :status => :raise}:
    #
    #  - nil: the original return value is returned, as if coallback had no
    #    effect
    #  - { :status => :raise}:
    #  - { :status => :override }:
    #
    #  - nil: reraise
    #  - { :status => :reraise }: reraise
    #  - { :status => :override }: eat exception
    #  - { :retry => :retry }: try the block again
    #
    #  CB can also declare that they are whitelisted and should not be run at the moment.

    attr_reader :klass, :method

    def initialize(klass, method)
      @method = method
      @klass = klass

      @has_pre  = respond_to? :pre
      @has_post = respond_to? :post
      @has_failing = respond_to? :failing

      raise(Sqreen::Exception, 'No callback provided') unless @has_pre || @has_post || @has_failing
    end

    def whitelisted?
      false
    end

    def pre?
      @has_pre
    end

    def post?
      @has_post
    end

    def failing?
      @has_failing
    end

    def to_s
      format('#<%s: %s.%s>', self.class, @klass, @method)
    end
  end
  # target_method, position, callback, callback class

  class DefaultCB < CB
    def pre(_inst, *args, &_block)
      Sqreen.log.debug "<< #{@klass} #{@method} #{Thread.current}"
      Sqreen.log.debug args.join ' '
      # log params
    end

    def post(_rv, _inst, *_args, &_block)
      # log "#{rv}"
      Sqreen.log.debug ">> #{@klass} #{@method} #{Thread.current}"
    end
  end

  class RunWhenCalledCB < CB
    def initialize(klass, method, &block)
      super(klass, method)

      raise 'missing block' unless block_given?
      @block = block
    end

    def pre(_inst, *_args, &_block)
      # FIXME: implement this removal
      @remove_me = true
      @block.call
    end
  end
end
