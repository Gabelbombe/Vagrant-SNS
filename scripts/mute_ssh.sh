#!/bin/bash

touch /home/vagrant/.ssh/config
chown vagrant:vagrant /home/vagrant/.ssh/config
chmod 0600 /home/vagrant/.ssh/config

cat << 'EOF' >> /home/vagrant/.ssh/config

  StrictHostKeyChecking no

EOF

exit 0
