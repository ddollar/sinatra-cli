require "rest-client"
require "sinatra/base"

module Sinatra
  module CLI

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
        output.puts
      end

      output.string.strip
    end

    get "*" do
      content_type "text/plain"
      command = commands[parse_command(params[:splat].first)]
      halt 404 unless command
    
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
      command = commands[parse_command(path)]
      foo = command.execute(parse_args(path), params)
      puts "FOO[#{foo}]"
      foo
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
