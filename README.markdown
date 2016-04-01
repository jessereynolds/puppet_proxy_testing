# Vagrant environment for Puppet Enterprise proxy testing

## Proxy Environments:

### Transparent

PE infra servers have:
- no direct internet access
- the ability to perform DNS lookups
- outbound port 80 and 443 intercepted at the network level and forwarded to a "transparent" proxy
- SSL uses HTTP CONNECT so there's no re-encryption

### Intercept

PE infra servers have:
- no direct internet access
- the ability to perform DNS lookups
- outbound port 80 and 443 intercepted at the network level and forwarded to a "intercept" proxy
- SSL connections are re-encrypted at the proxy, which means HTTP user agents need to trust the certificate presented by the proxy for all domains being accessed

### Explicit

PE infra servers have:
- no direct internet access
- the ability to perform DNS lookups
- to access the internet via http and https, a proxy configuration must be present

### Explicit and Authenticated

PE infra servers have:
- no direct internet access
- the ability to perform DNS lookups
- to access the internet via http and https, a proxy configuration must be present
- proxy configuration must include authentication credentials or token

## Tests:

- Code Manager can:
  - Deploy a control repo via https via proxy, eg a github repo
- PE Installation works behind proxy

## Setting up

### Environment Setup for Explicit Proxy

Create and start the proxy:

```bash
vagrant up /proxy/
```

Create and start master0:

```bash
vagrant up /master0/
```

Log into the [PE console](https://10.20.1.112).

Go into the PE Master classification group and ensure the following parameters to the `puppet_enterprise::profile::master` class are as follows:
- code_manager_auto_enable => true
- file_sync_enabled => true
- r10k_remote => "https://github.com/beergeek/evil_control.git"
- r10k_proxy => "http://10.20.1.114:3127"

Create a user `deploy` in the Operators group. Set the password using the password reset link pasted into another browser.

SSH in to master0 and sudo to root:

```
vagrant ssh /master0/
sudo su -
```

Do a puppet run.

Log the root user's puppet client tools in as user `deploy`:

```
puppet-access login deploy \
  --service-url https://master0.puppetlabs.vm:4433/rbac-api \
  --lifetime 7d
```

Ask code manager to deploy the production environment:

```
puppet-code -w deploy production
```

Here's the error you get in 2016.1.0:

```
# puppet-code -w deploy production
Deploying environment: production
[{"environment":"production","id":1,"status":"failed","error":{"kind":"puppetlabs.code-manager/deploy-failure","details":{"env-name":"production"},"msg":"Errors while deploying environment 'production' (exit code: 1):\nERROR\t -> Unable to determine current branches for Git source 'puppet' (/etc/puppetlabs/code-staging/environments)\nOriginal exception:\nFailed to connect to github.com: Connection timed out\n"}}]
```


## Examine the PE installer downloaded and used by pe_build...

```
$ (cd ~/.vagrant.d/pe_builds/ && ls -ld puppet-enterprise-2016.1.0-el-6-x86_64.tar.gz )
-rw-------  1 jesse  staff  366137126 31 Mar 10:12 puppet-enterprise-2016.1.0-el-6-x86_64.tar.gz

$ (cd ~/.vagrant.d/pe_builds/ && md5 puppet-enterprise-2016.1.0-el-6-x86_64.tar.gz )
MD5 (puppet-enterprise-2016.1.0-el-6-x86_64.tar.gz) = 8290764ce2c2565bcf84862b74adfa44
```

### Setting up for Intercept


```
vagrant up /master1/
```

Current error seen during installation (pe_bootstrap):

```
==> master1.puppetlabs.vm: Loaded plugins: fastestmirror, security
==> master1.puppetlabs.vm: Setting up Install Process
==> master1.puppetlabs.vm: Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=os&infra=stock error was
==> master1.puppetlabs.vm: 14: PYCURL ERROR 7 - "Failed to connect to 2a01:c0:2:4:0:acff:fe1e:1e52: Network is unreachable"
==> master1.puppetlabs.vm: Error: Cannot retrieve repository metadata (repomd.xml) for repository: base. Please verify its path and try again
==> master1.puppetlabs.vm: Running provisioner: pe_bootstrap...

...snip...

==> master1.puppetlabs.vm: STEP 4: INSTALL PACKAGES
==> master1.puppetlabs.vm: ## Installing packages from repositories...
==> master1.puppetlabs.vm: Loaded plugins: fastestmirror, security
==> master1.puppetlabs.vm: Setting up Install Process
==> master1.puppetlabs.vm: Determining fastest mirrors
==> master1.puppetlabs.vm: Error: Cannot find a valid baseurl for repo: base
==> master1.puppetlabs.vm: Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=os&infra=stoc
k error was
==> master1.puppetlabs.vm: 14: PYCURL ERROR 6 - "Couldn't resolve host 'mirrorlist.centos.org'"
==> master1.puppetlabs.vm:
==> master1.puppetlabs.vm: ========================================================================
==> master1.puppetlabs.vm: !! ERROR: Package installation failed
==> master1.puppetlabs.vm:
==> master1.puppetlabs.vm: ========================================================================
```

