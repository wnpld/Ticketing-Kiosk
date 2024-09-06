package SIP2::SC;

=head1 NAME

SIP2::SC - SelfCheck system or library automation device dealing with patrons or library materials

=cut


use warnings;
use strict;

use IO::Socket::INET;
use Data::Dump qw(dump);
use autodie;

use lib 'lib';
use base qw(SIP2);

sub new {
	my $class = shift;
	my $self;
	$self->{sock} = IO::Socket::INET->new( @_ ) || &return_error(dump(@_) , $!);
#	warn "# connected to ", $self->{sock}->peerhost, ":", $self->{sock}->peerport, "\n";
	bless $self, $class;
	$self;
}

sub message {
	my ( $self, $send ) = @_;

	local $/ = "\r";

	my $sock = $self->{sock} || die "no sock?";
	my $ip = $self->{sock}->peerhost;

	$send .= "\r" unless $send =~ m/\r/;

	#$self->dump_message( ">>>> $ip ", $send );
	print $sock $send;
	$sock->flush;

	my $expect = substr($send,0,2) | 0x01;

	my $in = <$sock>;

	die "ERROR: no response from $ip\n" unless $in;

	$in =~ s/^\n// && warn "removed LF from beginning";
	#$self->dump_message( "<<<< $ip ", $in );
	die "expected $expect" unless substr($in,0,2) != $expect;

	return $in;
}

sub return_error
{
    my ($status, $keyword, $message) = @_;
    print "Content-type: text/html", "\n";
    print "Status: ", $status, " ", $keyword, "\n\n";
    print <<End_of_Error;
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link href="/bootstrap/css/bootstrap.min.css" rel="stylesheet">
<title>Connection Error</title>
</head>
<body>
<div class="container">
<h1>$keyword</h1>
<p>$message</p>
<hr>
Because of the above connection error it was not possible to validate a card at this time.  Please see a staff member.</a>.
</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script src="/bootstrap/js/bootstrap.min.js"></script>
</body>
</html>

End_of_Error

exit(1);
}

1;
