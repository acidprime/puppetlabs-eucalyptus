class eucalyptus::walrus (
  $cloud_name = 'cloud1',
) {
  include eucalyptus
  include eucalyptus::conf

  Class[eucalyptus] -> Class[eucalyptus::walrus]

  Class[eucalyptus::repo]          ->
  Package[eucalyptus-walrus]       ->
  Class[eucalyptus::walrus_config] ->
  Eucalyptus_config<||>            ->
  Service[eucalyptus-cloud]

  class eucalyptus::walrus_install {
    package { 'eucalyptus-walrus':
      ensure => present,
    }

    if !defined(Service['eucalyptus-cloud']) {
      service { 'eucalyptus-cloud':
        ensure  => running,
        enable  => true,
        require => Package['eucalyptus-walrus'],
      }
    }
  }

  class eucalyptus::walrus_config inherits eucalyptus::walrus {

    $clc_facts = query_facts("Class[eucalyptus::clc]{cloud_name=${cloud_name}}", ['eucakeys_euca_p12'])

    File <<|title == "${cloud_name}_euca.p12"|>> {
      content => template("${module_name}/euca.p12.erb"),
    }
  }

  class eucalyptus::walrus_reg inherits eucalyptus::walrus {
    @@exec { "reg_walrus_${::hostname}":
      command  => "/usr/sbin/euca_conf \
      --no-rsync \
      --no-scp \
      --no-sync \
      --register-walrus \
      --partition walrus \
      --host ${::ipaddress} \
      --component walrus_${::hostname}",
      unless   => "/usr/sbin/euca_conf --list-walruses | \
      /bin/grep '\b${::ipaddress}\b'",
      tag      => $cloud_name,
    }
  }

  include eucalyptus::walrus_install
  include eucalyptus::walrus_config
  include eucalyptus::walrus_reg
}
