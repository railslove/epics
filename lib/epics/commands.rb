require 'yaml'

class Commander < ::Escort::ActionCommand::Base
  def init
    yml = {
      'keys_file'   => command_options[:keys_file],
      'passphrase'  => command_options[:passphrase],
      'url'         => command_options[:url],
      'host_id'     => command_options[:host_id],
      'user_id'     => command_options[:user_id],
      'partner_id'  => command_options[:partner_id],
    }.to_yaml

    File.open('.ebics.yml', 'w') { |f| f.write yml }
  end

  def execute
    client_params = YAML.load File.read('.ebics.yml') # TODO: or use on the fly config

    client = Epics::Client.new(
      client_params['keys_file'],
      client_params['passphrase'],
      client_params['url'],
      client_params['host_id'],
      client_params['user_id'],
      client_params['partner_id']
    )

    client.public_send(command_name, *arguments).inspect
  end
end
