require "rest-client"
require "sinatra/base"

module Sinatra
  module CLI
    def commands
      @@commands ||= {}
    end

    def command(path, &block)
      commands[path.split(' ').first] = Sinatra::CLI::Command.new(path, &block)
    end

    post "/command*" do
      path = params[:splat].to_s.split("/").reject(&:blank?).join(":")

      Sinatra::CLI.params = params

      halt 404 unless command = commands[path]
      command.call

      [ 200, {}, result.to_json ]
    end
  end

  register CLI

#     def commands
#       @@commands ||= {}
#     end
#
#     def command(path, &block)
#       commands[path] = block
#     end
#
#     def self.params=(params)
#       @@params = params
#     end
#
#     def params
#       @@params || {}
#     end
#
#     def args
#       params[:args] || []
#     end
#
#     def options
#       params[:options] || {}
#     end
#
#     def app
#       if options[:app]
#         options[:app]
#       else
#         output "Please specify an app with --app=APPNAME"
#         nil
#       end
#     end
#
#     def confirmed?
#       options[:confirm]
#     end
#
#     def confirmed_app?
#       options[:confirm] == app
#     end
#
#     def result
#       @@result ||= []
#     end
#
# ## dsl #######################################################################
#
#     def output(message=nil)
#       message ||= begin
#         stream = StringIO.new
#         yield stream
#         stream.string
#       end
#
#       result.push({ :type => "output", :message => message })
#     end
#
#     def confirm(message, &block)
#       if confirmed?
#         yield
#       else
#         result.push({ :type => "confirm", :message => message })
#       end
#     end
#
#     def confirm_app
#       if confirmed_app?
#         yield
#       else
#         result.push({ :type => "confirm_app" })
#       end
#     end
#   end
#
# ## sinatra ###################################################################
#
#   post "/command*" do
#     path = params[:splat].to_s.split("/").reject(&:blank?).join(":")
#
#     Sinatra::CLI.params = params
#
#     halt 404 unless command = commands[path]
#     command.call
#
#     [ 200, {}, result.to_json ]
#   end
  #
  # register CLI
end

require "sinatra/cli/command"
