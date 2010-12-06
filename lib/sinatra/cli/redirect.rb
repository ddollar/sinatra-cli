require "sinatra/cli"

class Sinatra::CLI::Redirect

  attr_reader :group, :namespace, :description, :url

  def initialize(group, namespace, description, url)
    @group = group
    @namespace = namespace
    @description = description
    @url = url
  end

## help ######################################################################

  def help
    "%-30s # %s" % [namespace, description]
  end

end

