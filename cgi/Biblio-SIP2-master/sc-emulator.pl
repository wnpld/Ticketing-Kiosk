#!/usr/bin/perl

use warnings;
use strict;

our $user     = 'sip2-user';
our $password = 'sip2-passwd';
our $patron   = 200000000042;
our $barcode  = 1302029710;
our $loc      = 'FFZG';

require 'config.pl' if -e 'config.pl';

use lib 'lib';
use SIP2::SC;

my $sc = SIP2::SC->new( $ENV{ACS} || '10.60.0.251:6001' );

# login
$sc->message("9300CN$user|CO$password|");

# SC Status
$sc->message("9900302.00");

# Patron Information
$sc->message("6300020091214    085452          AO$loc|AA$patron|AC$password|");

# Checkout
$sc->message("11YN20091214    124436                  AO$loc|AA$patron|AB$barcode|AC$password|BON|BIN|");

# Checkin
$sc->message("09N20091214    08142820091214    081428AP|AO$loc|AB$barcode|AC|BIN|");

# Checkin - invalid barcode
$sc->message("09N20091216    15320820091216    153208AP|AO$loc|AB200903160190|AC$password|BIN|");

# End Patron Session
$sc->message("3520140818    091937AO$loc|AA$patron");

# status
$sc->message("9900302.00");

