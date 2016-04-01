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

### Pre-requisites

- virtualbox
- vagrant
- the following vagrant plugins:
  - oscar
  - vagrant-hosts
  - vagrant-cachier (optional)

### Environment Setup for Explicit Proxy

Create and start the proxy:

```bash
vagrant up /proxy/
```

Create and start master0:

```bash
vagrant up /master0/
```

Log into the [master0 PE console](https://10.20.1.112).

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



### Setting up for Intercept

Create and start the proxy, if not done already:

```bash
vagrant up /proxy/
```

Create and start master1:

```bash
vagrant up /master1/
```

Log into the [master1 PE console](https://10.20.1.113).

Go into the PE Master classification group and ensure the following parameters to the `puppet_enterprise::profile::master` class are as follows:
- code_manager_auto_enable => true
- file_sync_enabled => true
- r10k_remote => "https://github.com/beergeek/evil_control.git"
- r10k_proxy should not be set

Create a user `deploy` in the Operators group. Set the password using the password reset link pasted into another browser.

SSH in to master1 and sudo to root:

```
vagrant ssh /master1/
sudo su -
```

Do a puppet run.

Log the root user's puppet client tools in as user `deploy`:

```
puppet-access login deploy \
  --service-url https://master1.puppetlabs.vm:4433/rbac-api \
  --lifetime 7d
```

Ask code manager to deploy the production environment:

```
puppet-code -w deploy production
```

If you get an error about an invalid certificate, it likely indicates that the CA root cert and chain from the proxy server have are not available on the system for rugged to use.

```
[root@master1 ~]# puppet-code -w deploy production
Deploying environment: production
[{"environment":"production","id":1,"status":"failed","error":{"kind":"puppetlabs.code-manager/deploy-failure","details":{"env-name":"production"},"msg":"Errors while deploying environment 'production' (exit code: 1):\nERROR\t -> Unable to determine current branches for Git source 'puppet' (/etc/puppetlabs/code-staging/environments)\nOriginal exception:\nThe SSL certificate is invalid\n"}}]
```

### Tests you can do to ensure the proxy is working:

Curl an http endpoint:

```
curl http://puppetlabs.com/
```

Curl an https endpoint:

```
curl https://puppetlabs.com/
```

Look at headers received by a remote website, ensure you can see appropriate data in the Via: and X-Forwarded-For: headers:

```
curl http://www.va.com.au/cgi-bin/test.sh
```

```
curl https://www.leaky.org/ip_tester.pl
```

### Running r10k like code manager does

```
sudo -u pe-puppet /usr/local/bin/r10k deploy environment -pv \
  -c /opt/puppetlabs/server/data/code-manager/r10k.yaml
```

eg:

```
[root@master1 ~]# sudo -u pe-puppet /usr/local/bin/r10k deploy environment -pv -c /opt/puppetlabs/server/data/code-manager/r10k.yaml
ERROR    -> Unable to determine current branches for Git source 'puppet' (/etc/puppetlabs/code-staging/environments)
Original exception:
The SSL certificate is invalid
```

It may help to increase the debug level with eg `-v debug2` and/or include the stack trace from where it hits the error with `--trace` eg:

```
[root@master1 ~]# sudo -u pe-puppet /usr/local/bin/r10k deploy environment -p -v debug2 --trace -c /opt/puppetlabs/server/data/code-manager/r10k.yaml
[2016-04-01 11:05:47 - DEBUG2] Reading configuration from "/opt/puppetlabs/server/data/code-manager/r10k.yaml"
[2016-04-01 11:05:47 - DEBUG1] Testing to see if feature rugged is available.
[2016-04-01 11:05:47 - DEBUG2] Attempting to load library 'rugged' for feature rugged
[2016-04-01 11:05:47 - DEBUG1] Feature rugged is available.
[2016-04-01 11:05:47 - DEBUG1] Setting Git provider to R10K::Git::Rugged
[2016-04-01 11:05:47 - DEBUG1] Testing to see if feature pe_license is available.
[2016-04-01 11:05:47 - DEBUG2] Attempting to load library 'pe_license' for feature pe_license
[2016-04-01 11:05:47 - DEBUG1] Feature pe_license is available.
[2016-04-01 11:05:47 - DEBUG2] pe_license feature is available, loading PE license key
[2016-04-01 11:05:47 - DEBUG] Fetching 'https://github.com/beergeek/evil_control.git' to determine current branches.
[2016-04-01 11:05:47 - DEBUG1] Fetching remote 'origin' at /opt/puppetlabs/server/data/code-manager/git/https---github.com-beergeek-evil_control.git
[2016-04-01 11:05:53 - ERROR] Unable to determine current branches for Git source 'puppet' (/etc/puppetlabs/code-staging/environments)
/opt/puppetlabs/puppet/lib/ruby/gems/2.1.0/gems/r10k-2.2.0/lib/r10k/source/git.rb:66:in `preload!'
/opt/puppetlabs/puppet/lib/ruby/gems/2.1.0/gems/r10k-2.2.0/lib/r10k/deployment.rb:36:in `each'
/opt/puppetlabs/puppet/lib/ruby/gems/2.1.0/gems/r10k-2.2.0/lib/r10k/deployment.rb:36:in `preload!'
/opt/puppetlabs/puppet/lib/ruby/gems/2.1.0/gems/r10k-2.2.0/lib/r10k/action/deploy/environment.rb:42:in `visit_deployment'
...snip...
Original exception:
The SSL certificate is invalid
/opt/puppetlabs/puppet/lib/ruby/gems/2.1.0/gems/rugged-0.21.4/lib/rugged/repository.rb:203:in `fetch'
/opt/puppetlabs/puppet/lib/ruby/gems/2.1.0/gems/rugged-0.21.4/lib/rugged/repository.rb:203:in `fetch'
/opt/puppetlabs/puppet/lib/ruby/gems/2.1.0/gems/r10k-2.2.0/lib/r10k/git/rugged/bare_repository.rb:55:in `block in fetch'
...snip...
```

