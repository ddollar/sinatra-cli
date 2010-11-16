require "sinatra/cli"

class Sinatra::CLI::Command

  def initialize(banner, &block)
    @banner = banner
    instance_eval &block
  end

## accessors #################################################################

  class Argument < Struct.new(:name, :help, :options); end
  class Option   < Struct.new(:name, :help, :options); end

  def arguments
    @arguments ||= {}
  end

  def options
    @options ||= {}
  end

## dsl #######################################################################

  def argument(name, help=nil, opts={})
    if help
      arguments[name.to_s] = Argument.new(name, help, opts)
      @arguments_order[name.to_s] << name
    end
    options[name.to_s]
  end

  def option(name, help=nil, opts={})
    if help
      options[name.to_s] = Option.new(name, help, opts)
      @options_order[name.to_s] << name
    end
    options[name.to_s]
  end

  def action(&block)
    @action = block if block_given?
    @action
  end

## execution #################################################################

  class Context
    attr_reader :args, :options, :platform

    def initialize(params)
      @args     = params[:args]
      @options  = params[:options]
      @platform = params[:platform]
    end

    def execute(&block)
      instance_eval &block
    end
  end

  def execute(params)
    Context.new(params).execute(@action)
  end

end
