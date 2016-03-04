yumrepo { 'epel':
  ensure         => 'present',
  descr          => 'Extra Packages for Enterprise Linux 6 - $basearch',
  enabled        => '1',
  failovermethod => 'priority',
  gpgcheck       => '0',
  mirrorlist     => 'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
}
yumrepo { 'squid':
  ensure         => 'present',
  baseurl        => 'http://www1.ngtech.co.il/rpm/centos/6/x86_64',
  descr          => 'SQUID repo for CentOS Linux 6 - ',
  enabled        => '1',
  failovermethod => 'priority',
  gpgcheck       => '0',
}
file { '/etc/sysconfig/iptables':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "# Managed by Puppet
*filter
:INPUT ACCEPT [650:123180]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [478:77348]
COMMIT
# Managed by Puppet
*nat
:PREROUTING ACCEPT [4:436]
:POSTROUTING ACCEPT [41:2520]
:OUTPUT ACCEPT [41:2520]
-A PREROUTING -s ${::networking['interfaces']['eth1']['network']}/24 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128
-A PREROUTING -s ${::networking['interfaces']['eth1']['network']}/24 -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 3129
COMMIT\n",
  notify => Service['iptables'],
}
service { 'iptables':
  ensure => running,
  enable => true,
}

package { ['squid','squid-helpers','perl-Crypt-OpenSSL-X509']:
  ensure  => present,
  require => Yumrepo['epel','squid'],
}
file { '/etc/squid/ssl_cert':
  ensure  => directory,
  owner   => 'squid',
  group   => 'squid',
  mode    => '0755',
  require => Package['squid'],
}
file { '/etc/squid/ssl_cert/myca.pem':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => '
-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAK6iLeUhwR/w9mBU
/un0z1iyJChO8RBTFf1j+bVBTkLM8iyRnrTCvf+hmHLD6DHYma2KaGs5g/BeHJaz
2VaIUNW5Jgg+oSUP3hrxn/VPSKYHUYnV6ehnerbB6IcIdOeP7T7vkqNWCeP7mlFd
M6+NDDbtJ1U9gA8dyBchgswm02sTAgMBAAECgYEAhwdbmVn6LCpzNpVB7cCfOqOz
lX9Eoiy8Sgstn1r5mmlBr/iA0J/rrWdTqxmTxkcGvMrSZmY4gHkkfdpeaKxKY09X
VTN+sIni7j8ZjZr+PjWWwf2m7SmTmCR33jspDb5FmXmnRMUm9qisNU0LorPYi84o
sJ2WUtuNzorhWORHUzECQQDizwktevhQGbfoIVdBiS/PbukAtBM7BmISci2xc9pu
vgiDIb7LsdbVixeQedWdw+2eRg4E7ShknDwMF3EfVnv3AkEAxRwO4qboO3h8h2D9
T0BpGCTzpDuG8o5J9HDeg0rs+5TWgHuxCgmBX+EPyCJWAxHEnIFHMHSrHyKw7+9P
96yqxQJBAIRWJtW5nW8nQm4YHhBoGlRfM2asq1fSRqDarByRK49YJCFXLDsv3dkl
Wi97Vw/BhUDHQWDQe7QQkNzBRMjzLksCQDsr8yQDaw//WZLigOi7s1D2NtYEsLw8
DuN8xq+vXHkh80ra1wjmVZpM3An+lMeTG+zHunFHdN+B8I/2zZDSmukCQBlejp9w
wh5uqEKYRT6rxTsCIANV7/mnv/A6INh/MoILJcy5V65z5chvU7LcRcf+NbWqgxA7
ZZAF1odsIXzKjqU=
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIICjjCCAfegAwIBAgIJALefH3EndO7SMA0GCSqGSIb3DQEBBQUAMGAxCzAJBgNV
BAYTAkFVMRUwEwYDVQQHDAxEZWZhdWx0IENpdHkxHDAaBgNVBAoME0RlZmF1bHQg
Q29tcGFueSBMdGQxHDAaBgNVBAMME3Byb3h5LnB1cHBldGxhYnMudm0wHhcNMTYw
MjI5MDIwMjI1WhcNMTkxMTI1MDIwMjI1WjBgMQswCQYDVQQGEwJBVTEVMBMGA1UE
BwwMRGVmYXVsdCBDaXR5MRwwGgYDVQQKDBNEZWZhdWx0IENvbXBhbnkgTHRkMRww
GgYDVQQDDBNwcm94eS5wdXBwZXRsYWJzLnZtMIGfMA0GCSqGSIb3DQEBAQUAA4GN
ADCBiQKBgQCuoi3lIcEf8PZgVP7p9M9YsiQoTvEQUxX9Y/m1QU5CzPIskZ60wr3/
oZhyw+gx2JmtimhrOYPwXhyWs9lWiFDVuSYIPqElD94a8Z/1T0imB1GJ1enoZ3q2
weiHCHTnj+0+75KjVgnj+5pRXTOvjQw27SdVPYAPHcgXIYLMJtNrEwIDAQABo1Aw
TjAdBgNVHQ4EFgQU9IScsdyWNIqtfgGMSWdfkDiTppkwHwYDVR0jBBgwFoAU9ISc
sdyWNIqtfgGMSWdfkDiTppkwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOB
gQBm5K39DiGoCxxQatGdTBnYUTi99lETTUDt1GWaOAA9nQQyOPlbPzb/8620/z67
stQ4xSPkESeTYpi/IMaWhQv/nr0ZqoMlNEDegDI/qLPnpDYqdnprx7VlgF2ku+Xk
+g9VDEzXapLHqQCtZgZRNwu6mz3ZLH2uKCXIJlMyP805mw==
-----END CERTIFICATE-----'
}
file { '/etc/squid/squid.conf':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "acl localnet src ${::networking['interfaces']['eth1']['network']}/24 # RFC1918 possible internal network
  acl internal dst ${::networking['interfaces']['eth1']['network']}/24
acl SSL_ports port 443
acl Safe_ports port 80    # http
acl Safe_ports port 21    # ftp
acl Safe_ports port 443   # https
acl Safe_ports port 70    # gopher
acl Safe_ports port 210   # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280   # http-mgmt
acl Safe_ports port 488   # gss-http
acl Safe_ports port 591   # filemaker
acl Safe_ports port 777   # multiling http
acl CONNECT method CONNECT
tcp_outgoing_address ${::networking['interfaces']['eth1']['ip']}
http_access deny internal
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow localhost
http_port 3127
http_port 3128 intercept
https_port 3129 intercept ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=/etc/squid/ssl_cert/myca.pem key=/etc/squid/ssl_cert/myca.pem
ssl_bump none localhost
ssl_bump server-first all
sslcrtd_program /usr/lib64/squid/ssl_crtd -s /var/lib/ssl_db -M 4MB
sslcrtd_children 8 startup=1 idle=1
http_access deny all
coredump_dir /var/spool/squid
refresh_pattern ^ftp:   1440  20% 10080
refresh_pattern ^gopher:  1440  0%  1440
refresh_pattern -i (/cgi-bin/|\\?) 0 0%  0
refresh_pattern .   0 20% 4320
debug_options ALL,2",
  require => Package['squid'],
}
exec { 'squid_ssl_db':
  command => '/usr/lib64/squid/ssl_crtd -c -s /var/lib/ssl_db; /bin/chown squid:squid /var/lib/ssl_db',
  unless  => '/usr/bin/test -d /var/lib/ssl_db',
  require => Package['squid'],
}
service { 'squid':
  ensure    => running,
  enable    => true,
  subscribe => [File['/etc/squid/squid.conf','/etc/squid/ssl_cert/myca.pem'],Exec['squid_ssl_db']],
}

