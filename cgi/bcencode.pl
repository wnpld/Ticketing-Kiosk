#!/usr/bin/perl
use CGI;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Common;

#Hash Salt
my $salt = $Common::hashsalt;

my $q = CGI->new;
my $barcode;
$barcode = $q->param('bc');
$barcode =~ s/[() \-]//g;

$barcode .= $salt;
my $hash = md5_hex($barcode);
$hash = uc($hash);

print "Content-type: text/plain\n\n";
print $hash;
exit;