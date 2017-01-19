#!/bin/bash

if [ `cat /etc/*release | grep VERSION_ID | awk -F\" '{print $2}' | awk -F. '{print $1}'` -eq "7" ]; then
	yum -y updatex
	yum -y install git https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter a desired name for this host [klip01]:"
		read HOST
		if [ -z "$HOST" ]; then
			HOST="klip01"
		fi
		echo $HOST | egrep "^[a-zA-Z0-9-]+$" >> /dev/null
		if [ "$?" -gt "0" ]; then
			echo "Invalid input\n"
		fi
	done
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter desired realm/domain name for this deployment:"
		read DOMAIN
		echo $DOMAIN | egrep "^[a-zA-Z0-9\.-]+\.[a-zA-Z0-9-]+$" >> /dev/null
		if [ "$?" -gt "0" ]; then
			echo "Invalid input\n"
		fi
	done
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter a desired environment for this host: eg: d for dev, t for test, ny for new york, etc. [d]:"
		read ENV
		if [ -z "$ENV" ]; then
			ENV="d"
		fi
		echo $ENV | egrep "^[a-zA-Z0-9_-]+$" >> /dev/null
		if [ "$?" -gt "0" ]; then
			echo "Invalid input\n"
		fi
	done
	nmcli general hostname $HOST.$ENV.$DOMAIN
	nmcli connection modify uuid `nmcli connection show --active | grep 802-3-ethernet | awk '{print $(NF-2)}' | tail -n 1` ipv4.dns-search $ENV.$DOMAIN
	systemctl restart NetworkManager.service
	if [ -f "/etc/cloud/cloud.cfg" ]; then
		sed -i -e "/^preserve_hostname:.*$/d" /etc/cloud/cloud.cfg
		echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
	fi
	yum -y install puppet-server
	sed -i -e "s/\[main]/\[main]\n    dns_alt_names = $( hostname )\n    environmentpath = \/etc\/puppet\/environments\n    parser = future\n    hiera_config = \/etc\/puppet\/hiera.yaml/g" /etc/puppet/puppet.conf
	sed -i -e "s/\[agent]/\[agent]\n    server = $( hostname )/g" /etc/puppet/puppet.conf
	echo -e "[master]\n    autosign = true" >> /etc/puppet/puppet.conf
	IFACE=`ip addr show up | grep LOWER_UP | grep -v "lo\:" | tail -n 1 | awk '{print \$2}' | tr -d ':'`
	sed -i -e "s/127.0.0.1.*$/127.0.0.1  localhost localhost.localdomain localhost4 localhost4.localdomain4\n`ip addr show $IFACE | grep "inet " | awk '{print \$2}' | awk -F/ '{print \$1}'`  $( hostname ) $( hostname )\./g" /etc/hosts
	mkdir -p /etc/puppet/environments/production/manifests /etc/puppet/environments/production/modules
	sleep 2
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter a password to be used for this deployment [random]:"
		read PASSWORD
		if [ -z "$PASSWORD" ]; then
			PASSWORD="$( (< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12) )"
			echo "Your password is: $PASSWORD
Please write it down, then press any key to continue."
			read -n 1 -s -p ""
		fi
		echo $PASSWORD | grep -P "^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,32}$" >> /dev/null
		if [ "$?" -gt "0" ]; then
			echo "Weak password (or too long). Try a stronger one.\n"
			bash -c "exit 1"
		fi
	done
#	git reset --hard ee0a7cb624560c0766c144a829522fbd270aadf4
	echo "---
:backends:
  - yaml

:hierarchy:
  - hiera
  - "../../../manifests/hiera"

:yaml:
  :datadir: /etc/puppet/environments/%{::environment}/manifests" >> /etc/puppet/hiera.yaml
	puppet master --verbose --no-daemonize&
	puppet module install jdshewey-modman
	puppet module install puppetlabs-firewall
	cd /etc/puppet/environments/production/modules/
	git clone https://github.com/jdshewey/puppet-ipa.git ipa
	cd ipa
	echo "---
profile::freeipa::public_dns: $DOMAIN
profile::freeipa::realm: $DOMAIN
profile::freeipa::dspw: $PASSWORD
profile::freeipa::adminpw: $PASSWORD" >> /etc/puppet/environments/production/manifests/hiera.yaml
	echo "node '$( hostname )'
{
	class 
	{ 
		'ipa':
			master  => true,
			adminpw => hiera(profile::freeipa::adminpw),
			dspw    => hiera(profile::freeipa::adminpw),
			realm	=> hiera(profile::freeipa::realm),
			domain	=> hiera(profile::freeipa::public_dns),
			dns     => true
	}
}" >> /etc/puppet/environments/production/manifests/init.pp
	puppet agent -t
#	sed -i -e "/^nameserver.*$/d" /etc/resolv.conf	#It's silly, but FreeIPA has a bug wherein it checks for the domain in DNS.
#	puppet agent -t									#If we break DNS, this lookup fails. If the domain already exists on the internet, 
													#FreeIPA will fail to install
else
	echo "This is only supported on CentOS/RedHat 7"
fi
