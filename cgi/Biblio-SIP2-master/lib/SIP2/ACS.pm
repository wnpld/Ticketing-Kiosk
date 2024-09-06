package SIP2::ACS;

=head1 NAME

SIP2::ACS - Automated Circulation System

=head1 DESCRIPTION

Basically just a simple proxy to real ACS server

=cut

use warnings;
use strict;

use IO::Socket::INET;
use IO::Select;

use Data::Dump qw(dump);

use lib 'lib';
use SIP2::SC;

sub proxy {
	my ( $listen, $server ) = @_;

	warn "listen on $listen for SIP2/RAW and connect to $server\n";

	my $lsn = IO::Socket::INET->new(Listen => 1, LocalAddr => $listen, Reuse => 1) or die $!;
	my $sel = IO::Select->new($lsn);

	my $sc;

	local $/ = "\r";

	while (1) {
		for my $sock ($sel->can_read(1)) {

			if ($sock == $lsn) {
				my $new = $lsn->accept;
				my $ip = $new->peerhost;
				warn "connection from $ip\n";
				$sel->add($new);
			} else {
				my $request = <$sock>;
				if ( ! defined $request ) {
					warn "disconnect from ", $sock->peerhost;
					$sel->remove( $sock );
					delete( $sc->{$sock} );
					close($sock);
					next;
				}
				my $ip = $sock->peerhost;
				warn "<< $ip ", dump($request);
				if ( ! $sc->{$sock} ) {
					warn "connect to $server for $sock\n";
					$sc->{$sock} = SIP2::SC->new( $server );
				}
				$request .= "\n" if $request !~ m/\n$/ && $ENV{CRLF};
				my $response = $sc->{$sock}->message( $request );
				$response .= "\n" if $response !~ m/\n$/ && $ENV{CRLF};
				#print $sock $response;
				warn ">> $ip ", dump($response);
			}
		}
	}
}

1;

