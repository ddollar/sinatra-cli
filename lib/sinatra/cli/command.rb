require "sinatra/cli"

class Sinatra::CLI::Command

  attr_reader :group, :banner, :description, :name

  def initialize(group, banner, description, &block)
    @group = group
    @banner = banner
    @description = description
    @name = banner.split(" ").first
    instance_eval &block
  end

## accessors #################################################################

  class Helped
    attr_reader :command, :name, :description, :options

    def initialize(command, name, description, options={})
      @command = command
      @name = name
      @description = description
      @options = options
    end

    def padding
      names = command.arguments.keys.concat(command.options.keys)
      names.map(&:length).max + 2
    end
  end

  class Argument < Helped
    def help
      "  %-#{padding}s %s" % [name.upcase, description]
    end
  end

  class Option < Helped
    def help
      "%-#{padding+2}s %s" % ["--#{name}", description]
    end
  end

  def arguments
    @arguments ||= {}
  end

  def options
    @options ||= {}
  end

## dsl #######################################################################

  def argument(name, help=nil, opts={})
    arguments[name.to_s] = Argument.new(self, name, help, opts) if help
    arguments[name.to_s]
  end

  def option(name, help=nil, opts={})
    options[name.to_s] = Option.new(self, name, help, opts) if help
    options[name.to_s]
  end

  def action(&block)
    @action = block if block_given?
    @action
  end

## help ######################################################################

  def help
    #"%-#{padding}s # %s" % [name, description]
    "%-30s # %s" % [name, description]
  end

  def padding
    group.commands.keys.map(&:length).max + 2
  end

## execution #################################################################

  class Context
    attr_reader :args, :options

    def initialize(args, options)
      @args     = args    || []
      @options  = options || {}
    end

    def run(block)
      instance_eval &block
    end

    def actions
      @@actions ||= []
    end

    def display(message)
      actions << ["display", message]
    end

    def warning(message)
      actions << ["warning", message]
    end

    def error(message)
      actions << ["error", message]
      throw :abort
    end

    def confirm(message)
      actions << ["confirm", message]
    end

    def execute(command)
      actions << ["execute", command]
    end
  end

  def execute(args, options={})
    context = Context.new(args, options)
    catch(:abort) { context.run(action) }
    context.actions.to_json
  end

end
