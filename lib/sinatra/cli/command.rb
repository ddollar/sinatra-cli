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
    def run(&block)
      catch(:abort) { instance_eval &block }
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

    def execute(command)
      actions << ["execute", command]
    end
  end

  class CommandContext < Context
    attr_reader :args, :options, :request

    def initialize(args, options, request)
      @args    = args    || []
      @options = options || {}
      @request = request
    end

    def confirm(message, &block)
      if options["confirm"]
        if options["confirm"].downcase[0..0] == "y"
          block.call
        else
          throw :abort
        end
      else
        actions << ["confirm", message]
      end
    end
  end

  class ErrorContext < Context
    attr_reader :exception, :response

    def initialize(exception, response)
      @exception = exception
      @response  = response
    end
  end

  def execute(args, options={}, request)
    context = CommandContext.new(args, options, request)
    context.run(&action)
    { "commands" => context.actions }.to_json
  end

end

