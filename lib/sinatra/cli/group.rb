require "sinatra/cli"
require "sinatra/cli/command"
require "sinatra/cli/redirect"

class Sinatra::CLI::Group
  attr_reader :banner, :options

  def initialize(banner, options={}, &block)
    @banner  = banner
    @options = options
    instance_eval &block
  end

  def commands
    @commands ||= {}
  end

  def redirects
    @redirects ||= {}
  end

  def command(banner, description, &block)
    command = Sinatra::CLI::Command.new(self, banner, description, &block)
    commands[command.name] = command
  end

  def redirect(namespace, description, url)
    redirect = Sinatra::CLI::Redirect.new(self, namespace, description, url)
    redirects[namespace] = redirect
  end

  def help
    output = StringIO.new

    output.puts "%s:" % banner
    commands.each do |name, command|
      output.puts "  %s" % command.help
    end
    redirects.each do |name, redirect|
      output.puts "  %s" % redirect.help
    end

    output.string.strip
  end

end
