module Epics
  Command = Struct.new(:name, :description, :options)

  COMMANDS = [
    Command.new(:HPB, "fetch your bank's public keys"),
    Command.new(:STA, "statements in MT940 format"),
    Command.new(:HAA, "available order types"),
    Command.new(:HTD, "user properties and settings"),
    Command.new(:HPD, "the available bank parameters"),
    Command.new(:PTK, "customer usage report in text format"),
  ]
end


class Commander < ::Escort::ActionCommand::Base
  def execute

    # Escort::Logger.output.puts "Command options: #{command_options}"
    # Escort::Logger.output.puts "Arguments: #{arguments}"
    # Escort::Logger.output.puts "User config: #{config}"

    STDOUT.puts Epics.const_get(command_name).new(*arguments).inspect
  end
end
