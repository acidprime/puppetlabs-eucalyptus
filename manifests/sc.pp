class eucalyptus::sc (
  $cloud_name = "cloud1",
  $cluster_name = "cluster1",
) {
  include eucalyptus
  include eucalyptus::conf
  Class[eucalyptus] -> Class[Eucalyptus::Conf] -> Class[eucalyptus::sc]

  Package[eucalyptus-sc]       ->
  Class[eucalyptus::sc_config] ->
  Eucalyptus_config<||>        ->
  Service[eucalyptus-cloud]

  class eucalyptus::sc_install {
    package { 'eucalyptus-sc':
      ensure => present,
    }
    if !defined(Service['eucalyptus-cloud']) {
      service { 'eucalyptus-cloud':
        ensure  => running,
        enable  => true,
        require => Package['eucalyptus-sc'],
      }
    }
  }


  class eucalyptus::sc_config inherits eucalyptus::sc {

    $clc_facts = query_facts("Class[eucalyptus::clc]{cloud_name=${cloud_name}}", ['eucakeys_euca_p12'])

     file { "${cloud_name}_euca.p12":
        path      => '/var/lib/eucalyptus/keys/euca.p12',
        content => template("${module_name}/euca.p12.erb"),
        owner     => 'eucalyptus',
        group     => 'eucalyptus',
        mode      => '0700',
        tag       => "${cloud_name}_euca.p12",
      }

  }

  class eucalyptus::sc_reg inherits eucalyptus::sc {

    Class[eucalyptus::sc_reg] -> Class[eucalyptus::sc_config]

    @@exec { "reg_sc_${::hostname}":
      command  => "/usr/sbin/euca_conf \
      --no-rsync \
      --no-scp \
      --no-sync \
      --register-sc \
      --partition ${cluster_name} \
      --host ${::ipaddress} \
      --component sc_${::hostname}",
      unless   => "/usr/sbin/euca_conf --list-scs | \
      /bin/grep '\b${::ipaddress}\b'",
      tag      => $cloud_name,
    }
  }

  include eucalyptus::sc_install, eucalyptus::sc_config, eucalyptus::sc_reg
}
