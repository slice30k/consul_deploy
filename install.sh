#!/bin/bash
######################################################
# Consul install script by Slice30k.
######################################################

CONSUL_VERSION=1.4.2
PACKAGE_NAME=consul_${CONSUL_VERSION}_linux_amd64.zip
DOWN_LOAD_URL=https://releases.hashicorp.com/consul/${CONSUL_VERSION}/${PACKAGE_NAME}

# Check older version
if [[ -e /usr/local/bin/consul ]]; then
	echo "Consul has been installed! Please use upgrade script instead!"
	exit -1
fi

# Download consul
if [[ !(-e ${PACKAGE_NAME}) ]]; then
	echo "Downloading package, this could take a while..."
	curl -O ${DOWN_LOAD_URL}
	if [[ $? != 0 ]]; then
		echo "download failure!"
		exit -1
	fi
fi
echo "package downloaded!"

# Unzip Consul
echo "Start installing consul."
unzip -d /usr/local/bin ${PACKAGE_NAME}
chown root:root /usr/local/bin/consul
consul --version
if [[ $? != 0 ]]; then
	echo "consul command not on PATH"
	exit -1
fi
# Setup consul environment 
consul -autocomplete-install
complete -C /usr/local/bin/consul consul
echo "creating user consul..."
useradd --system --home /etc/consul.d --shell /bin/false consul
echo "creating consul data directory..."
mkdir --parents /opt/consul
chown --recursive consul:consul /opt/consul
echo "creating consul config directory..."
mkdir --parents /etc/consul.d
touch /etc/consul.d/consul.hcl
chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/consul.hcl
(
cat << EOF
datacenter = "testqwe"
data_dir = "/opt/consul"
log_level = "INFO"
client_addr = "0.0.0.0"
ui = true
server = true
bootstrap_expect = 1
EOF
) > /etc/consul.d/consul.hcl

# Create system service
echo "creating consul.service ..."
touch /etc/systemd/system/consul.service
(
cat << EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
) > /etc/systemd/system/consul.service
systemctl daemon-reload

echo "install complete!"