# SNMP::Info::CiscoStack
# Max Baker
#
# Copyright (c)2003,2004,2006 Max Baker 
# All rights reserved.  
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the author nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::CiscoStack;
$VERSION = '1.03';
# $Id$

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE %PORTSTAT $INIT/;
@SNMP::Info::CiscoStack::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoStack::EXPORT_OK = qw//;

%MIBS    = (
            'CISCO-STACK-MIB'         => 'ciscoStackMIB',
            'CISCO-PORT-SECURITY-MIB' => 'ciscoPortSecurityMIB',
           );

%GLOBALS = (
            'sysip'       => 'sysIpAddr',    
            'netmask'     => 'sysNetMask',    
            'broadcast'   => 'sysBroadcast',
            'serial1'     => 'chassisSerialNumber',    
            'serial2'     => 'chassisSerialNumberString',
            'model1'      => 'chassisModel',    
            'ps1_type'    => 'chassisPs1Type',    
            'ps1_status'  => 'chassisPs1Status',    
            'ps2_type'    => 'chassisPs2Type',    
            'ps2_status'  => 'chassisPs2Status',    
            'slots'       => 'chassisNumSlots',    
            'fan'         => 'chassisFanStatus',
            # CISCO-PORT-SECURITY-MIB
            'cps_clear'     => 'cpsGlobalClearSecureMacAddresses',
            'cps_notify'    => 'cpsGlobalSNMPNotifControl',
            'cps_rate'      => 'cpsGlobalSNMPNotifRate',
            'cps_enable'    => 'cpsGlobalPortSecurityEnable',
            'cps_mac_count' => 'cpsGlobalTotalSecureAddress',
            'cps_mac_max'   => 'cpsGlobalMaxSecureAddress',
           );

%FUNCS   = (
            'i_type2'        => 'ifType',
            # CISCO-STACK-MIB::moduleEntry
            #   These are blades in a catalyst device
            'm_type'         => 'moduleType',
            'm_model'        => 'moduleModel',
            'm_serial'       => 'moduleSerialNumber',
            'm_status'       => 'moduleStatus',
            'm_name'         => 'moduleName',
            'm_ports'        => 'moduleNumPorts',
            'm_ports_status' => 'modulePortStatus',
            'm_hwver'        => 'moduleHwVersion',
            'm_fwver'        => 'moduleFwVersion',
            'm_swver'        => 'moduleSwVersion',
            # Router Blades :
            'm_ip'           => 'moduleIPAddress',
            'm_sub1'         => 'moduleSubType',
            'm_sub2'         => 'moduleSubType2',
            # CISCO-STACK-MIB::portEntry 
            'p_name'    => 'portName',
            'p_type'    => 'portType',
            'p_status'  => 'portOperStatus',
            'p_status2' => 'portAdditionalStatus',
            'p_speed'   => 'portAdminSpeed',
            'p_duplex'  => 'portDuplex',
            'p_port'    => 'portIfIndex',
            'p_rx_flow_control' => 'portOperRxFlowControl',
            'p_tx_flow_control' => 'portOperTxFlowControl',
            'p_rx_flow_control_admin' => 'portAdminRxFlowControl',
            'p_tx_flow_control_admin' => 'portAdminTxFlowControl',
            'p_oidx'    => 'portCrossIndex',
            # CISCO-STACK-MIB::PortCpbEntry
            'p_speed_admin'  => 'portCpbSpeed',
            'p_duplex_admin' => 'portCpbDuplex',
            # CISCO-PORT-SECURITY-MIB::cpsIfConfigTable
            'cps_i_limit_val'  => 'cpsIfInvalidSrcRateLimitValue',
            'cps_i_limit'      => 'cpsIfInvalidSrcRateLimitEnable',
            'cps_i_sticky'     => 'cpsIfStickyEnable',
            'cps_i_clear_type' => 'cpsIfClearSecureMacAddresses',
            'cps_i_shutdown'   => 'cpsIfShutdownTimeout',
            'cps_i_flood'      => 'cpsIfUnicastFloodingEnable',
            'cps_i_clear'      => 'cpsIfClearSecureAddresses',
            'cps_i_mac'        => 'cpsIfSecureLastMacAddress',
            'cps_i_count'      => 'cpsIfViolationCount',
            'cps_i_action'     => 'cpsIfViolationAction',
            'cps_i_mac_static' => 'cpsIfStaticMacAddrAgingEnable',
            'cps_i_mac_type'   => 'cpsIfSecureMacAddrAgingType',
            'cps_i_mac_age'    => 'cpsIfSecureMacAddrAgingTime',
            'cps_i_mac_count'  => 'cpsIfCurrentSecureMacAddrCount',
            'cps_i_mac_max'    => 'cpsIfMaxSecureMacAddr',
            'cps_i_status'     => 'cpsIfPortSecurityStatus',
            'cps_i_enable'     => 'cpsIfPortSecurityEnable',
            # CISCO-PORT-SECURITY-MIB::cpsIfVlanTable
            'cps_i_v_mac_count' => 'cpsIfVlanCurSecureMacAddrCount',
            'cps_i_v_mac_max'   => 'cpsIfVlanMaxSecureMacAddr',
            'cps_i_v'           => 'cpsIfVlanIndex',
            # CISCO-PORT-SECURITY-MIB::cpsIfVlanSecureMacAddrTable
            'cps_i_v_mac_status' => 'cpsIfVlanSecureMacAddrRowStatus',
            'cps_i_v_mac_age'    => 'cpsIfVlanSecureMacAddrRemainAge',
            'cps_i_v_mac_type'   => 'cpsIfVlanSecureMacAddrType',
            'cps_i_v_vlan'       => 'cpsIfVlanSecureVlanIndex',
            'cps_i_v_mac'        => 'cpsIfVlanSecureMacAddress',
            # CISCO-PORT-SECURITY-MIB::cpsSecureMacAddressTable
            'cps_m_status' => 'cpsSecureMacAddrRowStatus',
            'cps_m_age' => 'cpsSecureMacAddrRemainingAge',
            'cps_m_type' => 'cpsSecureMacAddrType',
            'cps_m_mac' => 'cpsSecureMacAddress',
           );

%MUNGE   = (
            'm_ports_status' => \&munge_port_status,
            'p_duplex_admin' => \&SNMP::Info::munge_bits,
            'cps_i_mac'      => \&SNMP::Info::munge_mac, 
            'cps_m_mac'      => \&SNMP::Info::munge_mac,
            'cps_i_v_mac'    => \&SNMP::Info::munge_mac,
           );

%PORTSTAT = (1 => 'other',
             2 => 'ok',
             3 => 'minorFault',
             4 => 'majorFault');

# Changes binary byte describing each port into ascii, and returns
# an ascii list separated by spaces.
sub munge_port_status {
    my $status = shift;
    my @vals = map($PORTSTAT{$_},unpack('C*',$status));
    return join(' ',@vals);
}

sub serial {
    my $stack = shift;
    my $serial1 = $stack->serial1();
    my $serial2 = $stack->serial2();

    return $serial1 if defined $serial1;
    return $serial2 if defined $serial2;
    return undef;
}

sub i_type {
    my $stack = shift;

    my $p_port = $stack->p_port() || {};
    my $p_type = $stack->p_type() || {};

    # Get more generic port types from IF-MIB
    my $i_type  = $stack->i_type2() || {};

    # Now Override w/ port entries
    foreach my $port (keys %$p_type) {
        my $iid = $p_port->{$port};
        next unless defined $iid;
        $i_type->{$iid} = $p_type->{$port};  
    }

    return $i_type;
}

# p_* functions are indexed to physical port.  let's index these
#   to snmp iid
sub i_name {
    my $stack = shift;

    my $p_port = $stack->p_port() || {};
    my $p_name = $stack->p_name() || {};

    my %i_name;
    foreach my $port (keys %$p_name) {
        my $iid = $p_port->{$port};
        next unless defined $iid;
        $i_name{$iid} = $p_name->{$port};
    }
    return \%i_name; 
}

sub i_duplex {
    my $stack = shift;

    #my $i_duplex = $stack->SUPER::i_duplex();
    my $p_port   = $stack->p_port()   || {};
    my $p_duplex = $stack->p_duplex() || {};

    my $i_duplex = {};
    foreach my $port (keys %$p_duplex) {
        my $iid = $p_port->{$port};
        next unless defined $iid;
        $i_duplex->{$iid} = $p_duplex->{$port};
    }
    return $i_duplex; 
}

sub i_duplex_admin {
    my $stack = shift;

    my $p_port         = $stack->p_port()         || {};
    my $p_duplex_admin = $stack->p_duplex_admin() || {};

    my %i_duplex_admin;
    foreach my $port (keys %$p_duplex_admin) {
        my $iid = $p_port->{$port};
        next unless defined $iid;
        my $duplex = $p_duplex_admin->{$port};
        next unless defined $duplex;

        my $string = 'other';
        # see CISCO-STACK-MIB for a description of the bits
        $string = 'half' if ($duplex =~ /001$/ or $duplex =~ /0100.$/);
        $string = 'full' if ($duplex =~ /010$/ or $duplex =~ /100.0$/);
        # we'll call it auto if both full and half are turned on, or if the
        #   specifically 'auto' flag bit is set.
        $string = 'auto' 
            if ($duplex =~ /1..$/ or $duplex =~ /110..$/ or $duplex =~ /..011$/);
       
        $i_duplex_admin{$iid} = $string;
    }
    return \%i_duplex_admin; 
}

sub set_i_speed_admin {
    # map speeds to those the switch will understand
    my %speeds = qw/auto 1 10 10000000 100 100000000 1000 1000000000/;

    my $stack = shift;
    my ($speed, $iid) = @_;
    my $p_port  = $stack->p_port() || {};
    my %reverse_p_port = reverse %$p_port;

    $speed = lc($speed);

    return 0 unless defined $speeds{$speed};

    $iid = $reverse_p_port{$iid};

    return $stack->set_p_speed($speeds{$speed}, $iid);
}

sub set_i_duplex_admin {
    # map a textual duplex to an integer one the switch understands
    my %duplexes = qw/half 1 full 2 auto 4/;

    my $stack = shift;
    my ($duplex, $iid) = @_;
    my $p_port  = $stack->p_port() || {};
    my %reverse_p_port = reverse %$p_port;

    $duplex = lc($duplex);

    return 0 unless defined $duplexes{$duplex};

    $iid = $reverse_p_port{$iid};

    return $stack->set_p_duplex($duplexes{$duplex}, $iid);
}


# $stack->interfaces() - Maps the ifIndex table to a physical port
sub interfaces {
    my $self = shift;
    my $i_index    = $self->i_index();
    my $portnames  = $self->p_port() || {};
    my %portmap    = reverse %$portnames;

    my %interfaces = ();
    foreach my $iid (keys %$i_index) {
        next unless defined $iid;
        my $if   = $i_index->{$iid};
        my $port = $portmap{$iid};
        $interfaces{$iid} = $port || $if;
    }

    return \%interfaces;
}

1;
__END__

=head1 NAME

SNMP::Info::CiscoStack - Intefaces to data from CISCO-STACK-MIB and CISCO-PORT-SECURITY-MIB

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $ciscostats = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $ciscostats->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoStack is a subclass of SNMP::Info that provides
an interface to the C<CISCO-STACK-MIB>.  This MIB is used across
the Catalyst family under CatOS and IOS.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

none.

=head2 Required MIBs

=over

=item CISCO-STACK-MIB

=item CISCO-PORT-SECURITY-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz or from
Netdisco-mib package at netdisco.org. 

=head1 GLOBALS

=over

=item $stack->broadcast()

(B<sysBroadcast>)

=item $stack->fan()

(B<chassisFanStatus>)

=item $stack->model()

(B<chassisModel>)

=item $stack->netmask()

(B<sysNetMask>)

=item $stack->ps1_type()

(B<chassisPs1Type>)

=item $stack->ps2_type()

(B<chassisPs2Type>)

=item $stack->ps1_status()

(B<chassisPs1Status>)

=item $stack->ps2_status()

(B<chassisPs2Status>)

=item $stack->serial()

(B<chassisSerialNumberString>) or (B<chassisSerialNumber>)

=item $stack->slots()

(B<chassisNumSlots>)

=back

=head2 CISCO-PORT-SECURITY-MIB globals

See CISCO-PORT-SECURITY-MIB for details.

=over

=item $stack->cps_clear()

B<cpsGlobalClearSecureMacAddresses>

=item $stack->cps_notify()

B<cpsGlobalSNMPNotifControl>

=item $stack->cps_rate()

B<cpsGlobalSNMPNotifRate>

=item $stack->cps_enable()

B<cpsGlobalPortSecurityEnable>

=item $stack->cps_mac_count()

B<cpsGlobalTotalSecureAddress>

=item $stack->cps_mac_max()

B<cpsGlobalMaxSecureAddress>

=back

=head1 TABLE METHODS

=head2 Interface Tables

=over

=item $stack->interfaces()

Crosses p_port() with i_index() to get physical names.

=item $stack->i_physical()

Returns a map to IID for ports that are physical ports, not vlans, etc.

=item $stack->i_type()

Crosses p_port() with p_type() and returns the results. 

Overrides with ifType if p_type() isn't available.

=item $stack->i_name()

Crosses p_name with p_port and returns results.

=item $stack->i_duplex()

Crosses p_duplex with p_port and returns results.

=item $stack->i_duplex_admin()

Crosses p_duplex_admin with p_port.

Munges bit_string returned from p_duplex_admin to get duplex settings.

=item $stack->set_i_speed_admin(speed, ifIndex)

    Sets port speed, must be supplied with speed and port ifIndex

    Speed choices are 'auto', '10', '100', '1000'

    Crosses $stack->p_port() with $stack->p_duplex() to
    utilize port ifIndex.

    Example:
    my %if_map = reverse %{$stack->interfaces()};
    $stack->set_i_speed_admin('auto', $if_map{'FastEthernet0/1'}) 
        or die "Couldn't change port speed. ",$stack->error(1);

=item $stack->set_i_duplex_admin(duplex, ifIndex)

    Sets port duplex, must be supplied with duplex and port ifIndex

    Speed choices are 'auto', 'half', 'full'

    Crosses $stack->p_port() with $stack->p_duplex() to
    utilize port ifIndex.

    Example:
    my %if_map = reverse %{$stack->interfaces()};
    $stack->set_i_duplex_admin('auto', $if_map{'FastEthernet0/1'}) 
        or die "Couldn't change port duplex. ",$stack->error(1);

=back

=head2 Module table

This table holds configuration information for each of the blades installed in
the Catalyst device.

=over

=item $stack->m_type()

(B<moduleType>)

=item $stack->m_model()

(B<moduleModel>)

=item $stack->m_serial()

(B<moduleSerialNumber>)

=item $stack->m_status()

(B<moduleStatus>)

=item $stack->m_name()

(B<moduleName>)

=item $stack->m_ports()

(B<moduleNumPorts>)

=item $stack->m_ports_status()

Returns a list of space separated status strings for the ports.

To see the status of port 4 :

    @ports_status = split(' ', $stack->m_ports_status() );
    $port4 = $ports_status[3];

(B<modulePortStatus>)

=item $stack->m_ports_hwver()

(B<moduleHwVersion>)

=item $stack->m_ports_fwver()

(B<moduleFwVersion>)

=item $stack->m_ports_swver()

(B<moduleSwVersion>)

=item $stack->m_ports_ip()

(B<moduleIPAddress>)

=item $stack->m_ports_sub1()

(B<moduleSubType>)

=item $stack->m_ports_sub2()

(B<moduleSubType2>)

=back

=head2 Modules - Router Blades

=over

=item $stack->m_ip()

(B<moduleIPAddress>)

=item $stack->m_sub1()

(B<moduleSubType>)

=item $stack->m_sub2()

(B<moduleSubType2>)

=back

=head2 Port Entry Table (CISCO-STACK-MIB::portTable)

=over

=item $stack->p_name()

(B<portName>)

=item $stack->p_type()

(B<portType>)

=item $stack->p_status()

(B<portOperStatus>)

=item $stack->p_status2()

(B<portAdditionalStatus>)

=item $stack->p_speed()

(B<portAdminSpeed>)

=item $stack->p_duplex()

(B<portDuplex>)

=item $stack->p_port()

(B<portIfIndex>)

=item $stack->p_rx_flow_control()

Can be either C<on> C<off> or C<disagree>

"Indicates the receive flow control operational status of the port. If the port
could not agree with the far end on a link protocol, its operational status
will be disagree(3)."

B<portOperRxFlowControl>

=item $stack->p_tx_flow_control()

Can be either C<on> C<off> or C<disagree>

"Indicates the transmit flow control operational status of the port. If the
port could not agree with the far end on a link protocol, its operational
status will be disagree(3)."

B<portOperTxFlowControl>

=item $stack->p_rx_flow_control_admin()

Can be either C<on> C<off> or C<desired>

"Indicates the receive flow control administrative status set on the port. If
the status is set to on(1), the port will require the far end to send flow
control. If the status is set to off(2), the port will not allow far end to
send flow control.  If the status is set to desired(3), the port will allow the
far end to send the flow control."

B<portAdminRxFlowControl>

=item $stack->p_tx_flow_control_admin()

Can be either C<on> C<off> or C<desired>

"Indicates the transmit flow control administrative status set on the port.  If
the status is set to on(1), the port will send flow control to the far end.  If
the status is set to off(2), the port will not send flow control to the far
end. If the status is set to desired(3), the port will send flow control to the
far end if the far end supports it."

B<portAdminTxFlowControl>

=back

=head2 Port Capability Table (CISCO-STACK-MIB::portCpbTable)

=over

=item $stack->p_speed_admin()

(B<portCpbSpeed>)

=item $stack->p_duplex_admin()

(B<portCpbDuplex>)

=back


=head2 CISCO-PORT-SECURITY-MIB - Interface Config Table

See CISCO-PORT-SECURITY-MIB for details.

=over

=item $stack->cps_i_limit_val()

B<cpsIfInvalidSrcRateLimitValue>

=item $stack->cps_i_limit()

B<cpsIfInvalidSrcRateLimitEnable>

=item $stack->cps_i_sticky()

B<cpsIfStickyEnable>

=item $stack->cps_i_clear_type()

B<cpsIfClearSecureMacAddresses>

=item $stack->cps_i_shutdown()

B<cpsIfShutdownTimeout>

=item $stack->cps_i_flood()

B<cpsIfUnicastFloodingEnable>

=item $stack->cps_i_clear()

B<cpsIfClearSecureAddresses>

=item $stack->cps_i_mac()

B<cpsIfSecureLastMacAddress>

=item $stack->cps_i_count()

B<cpsIfViolationCount>

=item $stack->cps_i_action()

B<cpsIfViolationAction>

=item $stack->cps_i_mac_static()

B<cpsIfStaticMacAddrAgingEnable>

=item $stack->cps_i_mac_type()

B<cpsIfSecureMacAddrAgingType>

=item $stack->cps_i_mac_age()

B<cpsIfSecureMacAddrAgingTime>

=item $stack->cps_i_mac_count()

B<cpsIfCurrentSecureMacAddrCount>

=item $stack->cps_i_mac_max()

B<cpsIfMaxSecureMacAddr>

=item $stack->cps_i_status()

B<cpsIfPortSecurityStatus>

=item $stack->cps_i_enable()

B<cpsIfPortSecurityEnable>

=back

=head2 CISCO-PORT-SECURITY-MIB::cpsIfVlanTable

=over

=item $stack->cps_i_v_mac_count()

B<cpsIfVlanCurSecureMacAddrCount>

=item $stack->cps_i_v_mac_max()

B<cpsIfVlanMaxSecureMacAddr>

=item $stack->cps_i_v()

B<cpsIfVlanIndex>

=back

=head2 CISCO-PORT-SECURITY-MIB::cpsIfVlanSecureMacAddrTable

=over

=item $stack->cps_i_v_mac_status()

B<cpsIfVlanSecureMacAddrRowStatus>

=item $stack->cps_i_v_mac_age()

B<cpsIfVlanSecureMacAddrRemainAge>

=item $stack->cps_i_v_mac_type()

B<cpsIfVlanSecureMacAddrType>

=item $stack->cps_i_v_vlan()

B<cpsIfVlanSecureVlanIndex>

=item $stack->cps_i_v_mac()

B<cpsIfVlanSecureMacAddress>

=back

=head2 CISCO-PORT-SECURITY-MIB::cpsSecureMacAddressTable

=over

=item $stack->cps_m_status()

B<cpsSecureMacAddrRowStatus>

=item $stack->cps_m_age()

B<cpsSecureMacAddrRemainingAge>

=item $stack->cps_m_type()

B<cpsSecureMacAddrType>

=item $stack->cps_m_mac()

B<cpsSecureMacAddress>

=back

=cut
