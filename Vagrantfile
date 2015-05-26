# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'csv'
require 'shellwords'

CREDS = {}
CLONE ='https://github.com/ehime/Library-AWS-SNS.git'

CSV.foreach('credentials/sns.csv', :headers => true, :col_sep => ',') do |row|
  CREDS[:IAM] = row['User Name']
  CREDS[:KEY] = row['Access Key Id']
  CREDS[:PEM] = row['Secret Access Key']
end

def bash(command)
  escaped_command = Shellwords.escape(command)
  system "bash -c #{escaped_command} 2>/dev/null"
end


bash('git pull') ## Do an initial pull so you are up to date...


# The RSA file below MUST BE the RSA that you use
# to connect to Github, otherwise you cannot clone.
bash('key_file=~/.ssh/github_rsa; eval "$(ssh-agent)" 1>/dev/null; [[ -z $(ssh-add -L |grep $key_file) ]] && ssh-add $key_file')

Vagrant.configure("2") do |config|

  config.vm.hostname = "sns.io"
  config.vm.box = "ubuntu/trusty64"
  config.vm.provision :shell, :path => "scripts/mute_ssh.sh"
  config.vm.provision :shell, :path => "scripts/bootstrap.sh",
                              :args => [ CLONE, CREDS[:KEY], CREDS[:PEM] ]

  # Visit the site at http://192.168.50.44
  config.vm.network :private_network, ip: "192.168.50.44"

  # Requires: vagrant plugin install vagrant-vbguest
  config.vbguest.auto_update = false

  # Required for passing ssh keys
  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.name = "SNSTesting"
  end

end
