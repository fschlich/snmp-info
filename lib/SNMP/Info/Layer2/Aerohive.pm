# SNMP::Info::Layer2::Aerohive
#
# Copyright (c) 2018 Eric Miller
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer2::Aerohive;

use strict;
use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Aerohive::ISA       = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Aerohive::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE/;

$VERSION = '3.61';

%MIBS = (
    %SNMP::Info::Layer2::MIBS,
    'AH-SYSTEM-MIB'    => 'ahSystemSerial',
    'AH-INTERFACE-MIB' => 'ahSSIDName',
);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,

    # AH-SYSTEM-MIB
    'serial' => 'ahSystemSerial',
    'os_bin' => 'ahFirmwareVersion',
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,

    # AH-INTERFACE-MIB::ahRadioAttributeTable
    'i_80211channel'      => 'ahRadioChannel',
    'dot11_cur_tx_pwr_mw' => 'ahRadioTxPower',

    # AH-INTERFACE-MIB::ahXIfTable
    'ah_i_ssidlist' => 'ahSSIDName',

    # AH-INTERFACE-MIB::ahAssociationTable
    'cd11_txrate'      => 'ahClientLastTxRate',
    'cd11_uptime'      => 'ahClientLinkUptime',
    'cd11_sigstrength' => 'ahClientRSSI',
    'cd11_rxpkt'       => 'ahClientRxDataFrames',
    'cd11_txpkt'       => 'ahClientTxDataFrames',
    'cd11_rxbyte'      => 'ahClientRxDataOctets',
    'cd11_txbyte'      => 'ahClientTxDataOctets',
    'cd11_ssid'        => 'ahClientSSID',
    'ah_c_vlan'        => 'ahClientVLAN',
    'ah_c_ip'          => 'ahClientIP',
);

%MUNGE
    = ( %SNMP::Info::Layer2::MUNGE, 'at_paddr' => \&SNMP::Info::munge_mac, );

sub layers {
    return '00000111';
}

sub vendor {
    return 'aerohive';
}

sub os {
    return 'hiveos';
}

sub os_ver {
    my $aerohive = shift;
    my $descr    = $aerohive->description();

    if ( $descr =~ m/\bHiveOS\s(\d\.\w+)\b/ix ) {
        return $1;
    }
    return;
}

sub model {
    my $aerohive = shift;
    my $descr    = $aerohive->description();

    if ( $descr =~ m/\b(?:Hive|)(AP\d+)\b/ix ) {
        return $1;
    }
    return;
}

sub i_ssidlist {
    my $aerohive = shift;
    my $partial  = shift;

    my $ssids = $aerohive->ah_i_ssidlist($partial) || {};

    my %i_ssidlist;
    foreach my $iid ( keys %$ssids ) {
        my $ssid = $ssids->{$iid};
        next if $ssid =~ /N\/A/i;

        $i_ssidlist{$iid} = $ssid;
    }
    return \%i_ssidlist;
}

sub i_ssidmac {
    my $aerohive = shift;
    my $partial  = shift;

    my $ssids = $aerohive->i_ssidlist($partial) || {};
    my $macs  = $aerohive->i_mac($partial)      || {};

    my %i_ssidmac;
    foreach my $iid ( keys %$ssids ) {
        my $mac = $macs->{$iid};
        next unless $mac;

        $i_ssidmac{$iid} = $mac;
    }
    return \%i_ssidmac;
}

# Break up the ahAssociationEntry INDEX into ifIndex and MAC Address.
sub _ah_association_index {
    my $idx     = shift;
    my @values  = split( /\./, $idx );
    my $ifindex = shift(@values);
    my $length  = shift(@values);
    return ( $ifindex, join( ':', map { sprintf "%02x", $_ } @values ) );
}

sub cd11_port {
    my $aerohive = shift;

    my $cd11_txrate = $aerohive->cd11_txrate();
    my $interfaces  = $aerohive->interfaces();

    my %ret;
    foreach ( keys %$cd11_txrate ) {
        my ( $ifindex, $mac ) = _ah_association_index($_);
        $ret{$_} = $interfaces->{$ifindex};
    }
    return \%ret;
}

sub cd11_mac {
    my $aerohive = shift;

    my $cd11_txrate = $aerohive->cd11_txrate();

    my %ret;
    foreach ( keys %$cd11_txrate ) {
        my ( $ifindex, $mac ) = _ah_association_index($_);
        $ret{$_} = $mac;
    }
    return \%ret;
}

# Does not support the standard Bridge MIB
sub bp_index {
    my $aerohive = shift;
    my $partial  = shift;

    my $i_index = $aerohive->i_index($partial) || {};

    my %bp_index;
    foreach my $iid ( keys %$i_index ) {
        my $index = $i_index->{$iid};
        next unless defined $index;

        $bp_index{$index} = $iid;
    }

    return \%bp_index;
}

sub qb_fw_port {
    my $aerohive = shift;
    my $partial  = shift;

    my $txrate = $aerohive->cd11_txrate($partial) || {};

    my $qb_fw_port = {};
    foreach my $idx ( keys %$txrate ) {
        my ( $fdb_id, $mac ) = _ah_association_index($idx);
        $qb_fw_port->{$idx} = $fdb_id;
    }
    return $qb_fw_port;
}

sub qb_fw_mac {
    my $aerohive = shift;
    my $partial  = shift;

    my $txrate = $aerohive->cd11_txrate($partial) || {};

    my $qb_fw_mac = {};
    foreach my $idx ( keys %$txrate ) {
        my ( $fdb_id, $mac ) = _ah_association_index($idx);
        $qb_fw_mac->{$idx} = $mac;
    }
    return $qb_fw_mac;
}

sub qb_fw_vlan {
    my $aerohive = shift;
    my $partial  = shift;

    my $vlans = $aerohive->ah_c_vlan($partial) || {};

    my $qb_fw_vlan = {};
    foreach my $idx ( keys %$vlans ) {
        my $vlan = $vlans->{$idx};
        next unless defined $vlan;
        $qb_fw_vlan->{$idx} = $vlan;
    }
    return $qb_fw_vlan;
}

# arpnip:
#
# This is the AP snooping on the MAC->IP mappings.
# Pretending this is arpnip data allows us to get MAC->IP
# mappings even for stations that only communicate locally.

sub at_paddr {
    my $aerohive = shift;

    my $txrate = $aerohive->cd11_txrate() || {};

    my $at_paddr = {};
    foreach my $idx ( keys %$txrate ) {
        my ( $fdb_id, $mac ) = _ah_association_index($idx);
        $at_paddr->{$idx} = $mac;
    }
    return $at_paddr;
}

sub at_netaddr {
    my $aerohive = shift;

    my $ips = $aerohive->ah_c_ip() || {};

    my $ret = {};
    foreach my $idx ( keys %$ips ) {
        next if ( $ips->{$idx} eq '0.0.0.0' );
        $ret->{$idx} = $ips->{$idx};
    }
    return $ret;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Aerohive - SNMP Interface to Aerohive Access Points

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $aerohive = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $aerohive->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from an
Aerohive wireless Access Point through SNMP. 

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $aerohive = new SNMP::Info::Layer2::Aerohive(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=back

=head2 Required MIBs

=over

=item F<AH-SYSTEM-MIB>

=item F<AH-INTERFACE-MIB>

=back

=head2 Inherited MIBs

See L<SNMP::Info::Layer2/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $aerohive->vendor()

Returns 'aerohive'.

=item $aerohive->os()

Returns 'hive_os'.

=item $aerohive->os_ver()

Returns the OS versionl extracted from C<sysDescr>.

=item $aerohive->os_bin()

Returns the firmware version extracted from C<ahFirmwareVersion>.

=item $aerohive->model()

Returns the model extracted from C<sysDescr>.

=item $aerohive->serial()

Returns the serial number extracted from C<ahSystemSerial>.

=back

=head2 Overrides

=over

=item $aerohive->layers()

Returns 00000111. Layer 2 and Layer 3 functionality through proprietary MIBs.

=back

=head2 Global Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=over

=item $aerohive->i_ssidlist()

Returns reference to hash.  SSID's recognized by the radio interface.

=item $aerohive->i_ssidmac()

With the same keys as i_ssidlist, returns the Basic service set
identification (BSSID), MAC address, the AP is using for the SSID.

=item $aerohive->i_80211channel()

Returns reference to hash.  Current operating frequency channel of the radio
interface.

C<ahRadioChannel>

=item $aerohive->dot11_cur_tx_pwr_mw()

Returns reference to hash.  Current transmit power, in milliwatts, of the
radio interface.

C<ahRadioTxPower>

=item $aironet->cd11_port()

Returns radio interfaces.

=item $aironet->cd11_mac()

Returns client radio interface MAC addresses.

=back

=head2 Overrides

=over

=item $aerohive->bp_index()

Simulates bridge MIB by returning reference to a hash mapping i_index() to
the interface iid.

=item $aerohive->qb_fw_port()

Returns reference to hash of forwarding table entries port interface
identifier (iid)

=item $aerohive->qb_fw_mac()

Returns reference to hash of forwarding table MAC Addresses

C<ahClientMac>

=item $aerohive->qb_fw_vlan()

Returns reference to hash of forwarding table entries VLAN ID

C<ahClientVLAN>

=back

=head2 Arp Cache Table Augmentation

The AP has knowledge of MAC->IP mappings for wireless clients.
Augmenting the arp cache data with these MAC->IP mappings enables visibility
for stations that only communicate locally.

=over

=item $aerohive->at_paddr()

C<ahClientMac>

=item $aerohive->at_netaddr()

C<ahClientIP>

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See L<SNMP::Info::Layer2/"TABLE METHODS"> for details.

=cut
