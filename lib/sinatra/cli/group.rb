require "sinatra/cli"
require "sinatra/cli/command"

class Sinatra::CLI::Group
  def initialize(banner, &block)
    instance_eval &block
  end

  def commands
    @commands ||= {}
  end

  def command(banner, description, &block)
    command = Sinatra::CLI::Command.new(self, banner, description, &block)
    commands[command.name] = command
  end
end
