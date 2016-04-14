require 'spec_helper'

describe 'CentOS 7 OS image', os_image: true do
  it_behaves_like 'every OS image'
  it_behaves_like 'a CentOS or RHEL based OS image'
  it_behaves_like 'a systemd-based OS image'
  it_behaves_like 'a Linux kernel 3.x based OS image'
  it_behaves_like 'a Linux kernel module configured OS image'

  context 'installed by base_centos' do
    describe file('/etc/locale.conf') do
      it { should be_file }
      it { should contain 'en_US.UTF-8' }
    end

    %w(
      centos-release
      epel-release
    ).each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  context 'installed by base_centos_packages' do
    %w(
      bison
      bzip2-devel
      cloud-utils-growpart
      cmake
      cronie-anacron
      curl
      dhclient
      e2fsprogs
      flex
      gdb
      glibc-static
      iptables
      libcap-devel
      libuuid-devel
      libxml2
      libxml2-devel
      libxslt
      libxslt-devel
      lsof
      NetworkManager
      net-tools
      nmap-ncat
      openssh-server
      openssl
      openssl-devel
      parted
      psmisc
      quota
      readline-devel
      rpm-build
      rpmdevtools
      rsync
      rsyslog
      rsyslog-relp
      rsyslog-gnutls
      rsyslog-mmjsonparse
      runit
      strace
      sudo
      sysstat
      systemd
      tcpdump
      traceroute
      unzip
      wget
      zip
    ).each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end

    describe file('/usr/sbin/ifconfig') do
      it { should be_executable }
    end
  end

  context 'installed by system_grub' do
    describe package('grub2-tools') do
      it { should be_installed }
    end
  end

  context 'overriding control alt delete (stig: V-38668)' do
    describe file('/etc/systemd/system/ctrl-alt-del.target') do
      it { should be_file }
      it { should contain '# escaping ctrl alt del' }
    end
  end

  context 'official Centos gpg key is installed (stig: V-38476)' do
    describe command('rpm -qa gpg-pubkey* 2>/dev/null | xargs rpm -qi 2>/dev/null') do
      its (:stdout) { should include('CentOS 7 Official Signing Key') }
    end
  end

  context 'ensure sendmail is removed (stig: V-38671)' do
    describe command('rpm -q sendmail') do
      its (:stdout) { should include ('package sendmail is not installed')}
    end
  end

  context 'ensure cron is installed and enabled (stig: V-38605)' do
    describe package('cronie') do
      it('should be installed') { should be_installed }
    end

    describe file('/etc/systemd/system/default.target') do
      it { should be_file }
      its(:content) { should match /^Requires=multi-user\.target/ }
    end

    describe file('/etc/systemd/system/multi-user.target.wants/crond.service') do
      it { should be_file }
      its(:content) { should match /^ExecStart=\/usr\/sbin\/crond/ }
    end
  end

  context 'ensure xinetd is not installed nor enabled (stig: V-38582)' do
    describe package('xinetd') do
      it('should not be installed') { should_not be_installed }
    end

    describe file('/etc/systemd/system/default.target') do
      it { should be_file }
      its(:content) { should match /^Requires=multi-user\.target/ }
    end

    describe file('/etc/systemd/system/multi-user.target.wants/xinetd.service') do
      it { should_not be_file }
    end
  end

  context 'ensure ypbind is not installed nor enabled (stig: V-38604)' do
    describe package('ypbind') do
      it('should not be installed') { should_not be_installed }
    end

    describe file('/etc/systemd/system/default.target') do
      it { should be_file }
      its(:content) { should match /^Requires=multi-user\.target/ }
    end

    describe file('/etc/systemd/system/multi-user.target.wants/ypbind.service') do
      it { should_not be_file }
    end
  end

  context 'ensure ypserv is not installed (stig: V-38603)' do
    describe package('ypserv') do
      it('should not be installed') { should_not be_installed }
    end
  end

  context 'ensure audit package file have correct permissions (stig: V-38663)' do
    describe command('rpm -V audit | grep ^.M') do
      its (:stdout) { should be_empty }
    end
  end

  context 'ensure audit package file have correct owners (stig: V-38664)' do
    describe command("rpm -V audit | grep '^.....U'") do
      its (:stdout) { should be_empty }
    end
  end

  context 'loading and unloading of dynamic kernel modules must be audited (stig: V-38580)' do
    describe file('/etc/audit/rules.d/audit.rules') do
      its(:content) { should match /^-w \/sbin\/insmod -p x -k modules$/ }
      its(:content) { should match /^-w \/sbin\/rmmod -p x -k modules$/ }
      its(:content) { should match /^-w \/sbin\/modprobe -p x -k modules$/ }
      its(:content) { should match /-a always,exit -F arch=b64 -S init_module -S delete_module -k modules/ }
    end
  end

  context 'gpgcheck must be enabled (stig: V-38483)' do
    describe file('/etc/yum.conf') do
      its(:content) { should match /^gpgcheck=1$/ }
    end
  end

  context 'installed by bosh_sysctl' do
    describe file('/etc/sysctl.d/60-bosh-sysctl.conf') do
      it { should be_file }

      it 'must limit the ability of processes to have simultaneous write and execute access to memory. (only centos) (stig: V-38597)' do
        should contain /^kernel.exec-shield=1$/
      end
    end
  end
end
