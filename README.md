# FLIP Installer
This is a bash script for bootstrapping a FLIP stack. This is the fastest way to deploy a fully working stack in your environment and is intended to fully install and configure your environment for use with minimal user input.

# What is a FLIP stack?
FLIP stands for [Foreman](https://theforeman.org), [Linux](https://www.centos.org), [IPA](https://www.freeipa.org/page/Main_Page) and [Puppet](https://puppet.com/). This is essentially a [Red Hat Satellite 6](https://access.redhat.com/products/red-hat-satellite) + [FreeIPA](https://www.freeipa.org/page/Main_Page) user (LDAP and Kerberos) and DNS management system deployment. FreeIPA and Satellite 6 really fit together like a hand in a glove, but oddly, FreeIPA is not included as part of the Satellite 6 stack. Furthermore, Satellite 6 is really based on Katello. The Katello project brings together the [Candlepin](http://www.candlepinproject.org/) license management system and [Pulp](http://pulpproject.org/) backends with heavy [Kickstart](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/sect-kickstart-howto.html) server deployment script integration as well as loose [Docker](https://www.docker.com/) container and Puppet integration/management. Katello is then skinned with [The Foreman](https://www.theforeman.org/) front end. More recently, it appears that Katello is merging into The Foremen having moved all of the Katello docs to their site. This means that the Katello stack (minus Candlepin license management) is available for all CentOS servers and that your CentOS server can manage all of your RedHat servers (including licensing) or vice-versa. Katello also integrates with numerous virtualization systems and cloud providers including VMWare, OpenStack, Amazon Web Services, [Google's cloud](https://cloud.google.com) platform, [Rackspace](https://www.rackspace.com) and [others](https://theforeman.org/manuals/1.14/index.html#5.2ComputeResources). This helps to prevent you from being tied to a specific cloud by using, for example Amazon's automated deployment and continuous deployment tools. You can freely move between clouds or your own environment.  This script seeks to: 

- Unify and abstract the setup for all of these softwares by cutting down on repetitive information needed by the two installers (Katello and IPA)
- Abstract and gloss over the version differences between Satellite 6 and Katello installers and provide a single stream for installation
- Unify two significant pieces of the full stack under a single umbrella
- Make installation easier by accounting for known bugs and installation challenges and avoiding these pitfalls altogether

#System Requirements

At least 2 GB of RAM is required for the installer to work properly. Katello recommends at least 250 GB disk space - 50 for mongodb storage and 200 for RPM storage.

#Red Hat is Recommended

There are numerous know bugs and integrations issues. I highly recommend that you purchase a Red Hat subscription for at least your development FLIP stack to allow you to iron out integration issues within your environment. You can then promote these fixes to CentOS server in test and production if you are that cheap or manage CentOS boxes with your licensed stack.

# This is a work in progress
Currently, this script will take you Red Hat 7 / CentOS 7 server and deploy a FreeIPA installation using puppet. A list of To Do tasks for this project are:
 - Install DNS using ipa-dns-install using the --force option - see manpage https://linux.die.net/man/1/ipa-dns-install. This will require updates or an overhaul to https://github.com/jdshewey/puppet-ipa to perform second step. Should also consider renaming this to something more unique like ipaman and release this as a full module. The origional module https://github.com/huit/puppet-ipa appears to be abandonware and BitBrew (https://github.com/BitBrew/puppet-ipa) has not republished his active module on PuppetForge and does not tag stable releases.
 - Ensure IPA is fully configured - may need to do some JSON interaction to get it online
 - Research or write a puppet module for deploying the katello stack and implement it in the puppet manifest bootstrapped by this script. Need to make sure that temp puppet environment to bootstrap doesn't collide with katello installation.
 - Re-implement all of this to have the existing FLIP stack in dev spawn a prod FLIP stack or a FLIP stack for an alternate location
 - Update this documentation
