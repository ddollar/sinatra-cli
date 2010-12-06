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

    def group_for_prefix(prefix)
      groups.values.detect { |g| g.options[:prefix] == prefix }
    end

    def group(banner, options={}, &block)
      groups[banner] = Sinatra::CLI::Group.new(banner, options, &block)
    end

    def commands
      groups.inject({}) do |hash, (name, group)|
        group.commands.each do |name, command|
          hash.update(name => command)
        end
        hash
      end
    end

    def command_for_full_name(path)
      commands.values.detect { |c| c.full_name == path }
    end

    def redirects
      groups.inject({}) do |hash, (name, group)|
        group.redirects.each do |name, redirect|
          hash.update(name => redirect)
        end
        hash
      end
    end

    def match_redirect(command)
      if redirect = redirects[command.split(":").first]
        redirect.url
      else
        nil
      end
    end

    helpers do
      def cli_executable
        request.env["HTTP_X_CLI_EXECUTABLE"]
      end

      def cli_version
        request.env["HTTP_X_CLI_VERSION"]
      end

      def attempt_redirect(command)
        if match = redirects[command.split(":").first]
          redirect(match.url + request.path)
        end
      end
    end

    get "/" do
      content_type "text/plain"
      output = StringIO.new

      output.puts "Usage: #{cli_executable} <COMMAND>"
      output.puts
      groups.each do |banner, group|
        output.puts group.help
        output.puts
      end

      output.string.strip
    end

    get "*" do
      content_type "text/plain"
      raw_command = parse_command(params[:splat].first)
      command = command_for_full_name(raw_command)

      unless command
        attempt_redirect(raw_command)
        if group = group_for_prefix(raw_command)
          return group.help
        end
        halt 404
      end

      output  = StringIO.new
      output.puts "Usage: %s %s" % [cli_executable, command.banner]
      output.puts
      output.puts "  %s" % command.description
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
