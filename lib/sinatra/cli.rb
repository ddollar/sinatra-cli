require "rest-client"
require "sinatra/base"

module Sinatra
  module CLI

    def error_handlers
      @@error_handlers ||= {}
    end

    def error_handler(klass, &block)
      error_handlers[klass] = block
    end

    def groups
      @@groups ||= {}
    end

    def group(banner, &block)
      groups[banner] = Sinatra::CLI::Group.new(banner, &block)
    end

    def commands
      groups.inject({}) do |hash, (name, group)|
        group.commands.each do |name, command|
          hash.update(name => command)
        end
        hash
      end
    end

    def redirects
      groups.inject({}) do |hash, (name, group)|
        group.redirects.each do |name, redirect|
          hash.update(name => redirect)
        end
        hash
      end
    end

    helpers do
      def cli_executable
        request.env["HTTP_X_CLI_EXECUTABLE"]
      end

      def cli_version
        request.env["HTTP_X_CLI_VERSION"]
      end
    end

    get "/" do
      content_type "text/plain"
      output = StringIO.new

      output.puts "Usage: #{cli_executable} <COMMAND>"
      output.puts
      groups.each do |banner, group|
        output.puts "%s:" % banner
        group.commands.each do |name, command|
          output.puts "  %s" % command.help
        end
        group.redirects.each do |name, redirect|
          output.puts "  %s" % redirect.help
        end
        output.puts
      end

      output.string.strip
    end

    get "*" do
      content_type "text/plain"
      raw_command = parse_command(params[:splat].first)
      command = commands[raw_command]

      unless command
        redir = redirects[raw_command.split(':').first]
        redirect redir.url if (redir && redir.url)
        halt 404
      end

      output  = StringIO.new
      output.puts "Usage: %s %s" % [cli_executable, command.banner]
      output.puts
      unless command.arguments.empty?
        output.puts "Arguments:"
        command.arguments.each do |(name, arg)|
          output.puts "  #{arg.help}"
        end
        output.puts
      end
      unless command.options.empty?
        output.puts "Options:"
        command.options.each do |(name, option)|
          output.puts "  #{option.help}"
        end
        output.puts
      end
      output.string.strip
    end

    post "*" do
      content_type "application/json"
      path = params.delete("splat").first
      raw_command = parse_command(path)
      command = commands[raw_command]

      unless command
        redir = redirects[raw_command.split(':').first]
        redirect redir.url if (redir && redir.url)
        halt 404
      end

      args    = parse_args(path)
      options = params
      begin
        command.execute(args, options, request)
      rescue Exception => ex
        error_handlers.each do |klass, handler|
          if ex.is_a?(klass)
            context = Sinatra::CLI::Command::ErrorContext.new(ex, response)
            context.run(&handler)
            return { "commands" => context.actions }.to_json
          end
        end
        context = Sinatra::CLI::Command::ErrorContext.new(ex, response)
        context.run do
          context.error "unknown error: #{ex.message}\n#{ex.backtrace.first}"
        end
        { "commands" => context.actions }.to_json
      end
    end

    def parse_command(splat)
      splat.split(";").first.split("/").reject { |s| s.strip == "" }.join(":")
    end

    def parse_args(splat)
      splat.split(";")[1..-1]
    end

  end

  register CLI

end

require "sinatra/cli/group"
