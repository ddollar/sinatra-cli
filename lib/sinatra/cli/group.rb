require "sinatra/cli"
require "sinatra/cli/command"
require "sinatra/cli/redirect"

class Sinatra::CLI::Group
  def initialize(banner, &block)
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

end
