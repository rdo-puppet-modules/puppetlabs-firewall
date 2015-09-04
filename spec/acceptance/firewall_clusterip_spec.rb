require 'spec_helper_acceptance'

describe 'firewall type', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  before(:all) do
    shell('iptables --flush; iptables -t nat --flush; iptables -t mangle --flush')
    shell('ip6tables --flush; ip6tables -t nat --flush; ip6tables -t mangle --flush')
  end

    # Have to comment out el-7 as the interface name is inconsistent
    if default['platform'] !~ /el-7/
      describe 'clusterip' do
        context 'cluster ipv4 test' do
          it 'applies' do
            pp = <<-EOS
              class { '::firewall': }
              firewall {
                '830 - clusterip test':
                  chain                 => 'FORWARD',
                  jump                  => 'CLUSTERIP',
                  destination           => '1.1.1.1',
                  iniface               => 'eth0',
                  clusterip_new         => true,
                  clusterip_hashmode    => "sourceip",
                  clusterip_clustermac  => "01:00:5E:00:00:00",
                  clusterip_total_nodes => "2",
                  clusterip_local_node  => "1",
                  clusterip_hash_init   => "1337",
              }
            EOS

            apply_manifest(pp, :catch_failures => true)
          end

          it 'should contain the rule' do
            shell('iptables-save') do |r|
              expect(r.stdout).to match(/-A FORWARD -d (1.1.1.1\/32|1.1.1.1) -i eth0 -p tcp -m comment --comment "830 - clusterip test" -j CLUSTERIP --new --hashmode sourceip --clustermac 01:00:5E:00:00:00 --total-nodes 2 --local-node 1 --hash-init 1337/)
            end
          end
        end
      end
    else
      pending("MODULES-2124 should be resolved for clusterip RHEL7 support") do
        true.should be(true)
      end
    end
end
