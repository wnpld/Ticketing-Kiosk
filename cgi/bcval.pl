#!/usr/bin/perl
use lib '/usr/lib/cgi-bin/Biblio-SIP2-master/lib/';
use SIP2::SC;
use POSIX qw(strftime);
use CGI;
use DBI;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Common;

#Adjustable Variables

#Before minutes = how long before the event starts that it shows up as available for
#tickets for district cardholders
my $beforeminutes = 480;

#Buffer minutes = minutes after the start of an event in which tickets are still available
my $bufferminutes = 4;

#Also code by the word IMPORTANT (around line 100) needs to be adjusted for appropriate SIP library codes

### End of Variables Likely to be Manually Adjusted ###

#SIP Variables
my $address = $Common::sipserver;
my $SIPlogin = $Common::siplogin;
my $SIPpassword = $Common::sippassword;
my $location = $Common::siplocation;


#Database Variables
my ($user_name, $password, $sth);
($user_name, $password) = ($Common::dbuser, $Common::dbpassword);
my $db_name = $Common::databasename;
my $dsn = "DBI:mysql:database=$db_name";

#Hash Salt
my $salt = $Common::hashsalt;

#Other variables
my $phone = 0;
my $date = strftime "%Y%m%d    %H%M%S", localtime;

my $q = CGI->new;
my $barcode;
if (defined($testbarcode)) {
    $barcode = $testbarcode;
} else {
    $barcode = $q->param('bc');
}

##Testing
#$barcode = "21123001540801";

my $response = "{ ";
my $indistrict = 0;
if ($barcode =~ /^update$/) {
    #This is an update query.  It won't be used to procure tickets.
    #Set responses like an invalid card but set indistrict to true
    $response .= "\"valid\": 0, \"library\": 0, \"status\": \"update\", \"fine\": 0, ";
    $indistrict = 2;
} elsif ($barcode =~ /^\d{10}$/) {
    #This is a phone number not a barcode, so don't bother checking it
    #Phone numbers are treated as out of district cards
    $response .= "\"valid\": 2, \"library\": 0, \"status\": \"phone\", \"fine\": 0, ";
} else {

    my $sc = SIP2::SC->new( $ENV{ACS} || $address );

    # login
    my $message = "9300CN$SIPlogin|CO$SIPpassword|CP$location|";
    $message = append_checksum($message);
    my $sipstatus = $sc->message($message);
#    print $sipstatus . "\n";

    #Patron Information
    $message = "63000$date          AO$location|AA$barcode|";
    $message = append_checksum($message);
    my $sipresponse = $sc->message($message);

    my ($authbc, $code, $library, $status, $fine);
    my @values = split(/\|/, $sipresponse);

    foreach my $value (@values) {
        if ($value =~ /([A-Z][A-Z0-9])([A-Za-z\- 0-9]+)/) {
            if ($1 eq "AA") {
                $authbc = $2;
            } elsif ($1 eq "U4") {
                $library = $2;
            } elsif ($1 eq "PE") {
                $code = $2;
            } elsif ($1 eq "AF") {
                $status = $2;
            } elsif ($1 eq "BV") {
                $fine = $2;
            }
        }
    }

#IMPORTANT -- This needs to be customized based on your situation
    if ($status =~ /Patron status is ok/) {
        if ($code eq "WNK") {
            $response .= "\"valid\": 1, \"library\": 7, \"status\": \"ok\", ";
            $indistrict = 1;
        } elsif ($code eq "WBK") {
            $response .= "\"valid\": 1, \"library\": 6, \"status\": \"ok\", ";
            $indistrict = 1;
        } elsif ($code eq "WLK") {
            $response .= "\"valid\": 1, \"library\": 5, \"status\": \"ok\", ";
        } elsif ($code eq "NBK") {
            $response .= "\"valid\": 1, \"library\": 4, \"status\": \"ok\", ";
        } elsif ($code eq "GVK") {
            $response .= "\"valid\": 1, \"library\": 3, \"status\": \"ok\", ";
        } elsif ($code eq "GCK") {
            $response .= "\"valid\": 1, \"library\": 2, \"status\": \"ok\", ";
        } elsif ($code eq "EVK") {
            $response .= "\"valid\": 1, \"library\": 1, \"status\": \"ok\", ";
        } else {
            $response .= "\"valid\": 1, \"library\": 0, \"status\": \"ok\", ";
        }
    } elsif ($status =~ /Patron does not exist/) {
        $response .= "\"valid\": 0, \"library\": 0, \"status\": \"invalid\", ";
    } else {
        $response .= "\"valid\": 1, \"library\": 0, \"status\": \"$status\", ";
    }
    if ($fine > 10) {
        $response .= "\"fine\": $fine, ";
    } else {
        $response .= "\"fine\": 0, ";
    }
}

#Before responding based on SIP response, check for other registrations
#and program availability

my $salt .= $barcode;
my $hash = md5_hex($barcode);
$response .= "\"id\": \"$hash\", ";

my $dbh = DBI->connect($dsn, $user_name, $password, { RaiseError => 1} ) or die &return_error("Could not connect to database", $DBI::errstr);

my $today = strftime '%Y-%m-%d', localtime;
my $time = strftime '%R', localtime;
my $sth;

#This ugly SQL query gets a list of events and their ticket quantities.
$sth = $dbh->prepare('SELECT ProgramName, ProgramTime, RegistrationDelay, LocationDescription, AgeRange, LocationCapacity, GraceSpaces, TicketsHeld, EventID, SUM(OoDTickets) AS OoDTickets, SUM(DTickets) AS DTickets FROM ((SELECT p.ProgramName, p.ProgramTime, p.SecondTierMinutes As RegistrationDelay, l.LocationDescription, p.AgeRange, p.Capacity AS LocationCapacity, p.Grace as GraceSpaces, e.TicketsHeld, e.EventID, 0 AS OoDTickets, 0 AS DTickets FROM TicketedPrograms p INNER JOIN TicketedEvents e ON p.ProgramID = e.ProgramID INNER JOIN TicketLocations l ON p.LocationID = l.LocationID WHERE e.EventDate = ? AND ? BETWEEN DATE_SUB(p.ProgramTime, INTERVAL ' . $beforeminutes . ' MINUTE) AND DATE_ADD(p.ProgramTime, INTERVAL ' . $bufferminutes . ' MINUTE)) UNION ALL (SELECT p.ProgramName, p.ProgramTime, p.SecondTierMinutes As RegistrationDelay, l.LocationDescription, p.AgeRange, p.Capacity AS LocationCapacity, p.Grace as GraceSpaces, e.TicketsHeld, e.EventID, (IFNULL(t.Adults,0) + IFNULL(t.Children,0)) AS OoDTickets, 0 AS DTickets FROM TicketedPrograms p INNER JOIN TicketedEvents e ON p.ProgramID = e.ProgramID INNER JOIN TicketLocations l ON p.LocationID = l.LocationID INNER JOIN Tickets t ON e.EventID = t.EventID WHERE e.EventDate = ? AND ? BETWEEN DATE_SUB(p.ProgramTime, INTERVAL ' . $beforeminutes . ' MINUTE) AND DATE_ADD(p.ProgramTime, INTERVAL ' . $bufferminutes . ' MINUTE) AND t.DistrictResidentID < 6)  UNION ALL  (SELECT p.ProgramName, p.ProgramTime, p.SecondTierMinutes As RegistrationDelay, l.LocationDescription, p.AgeRange, p.Capacity AS LocationCapacity, p.Grace as GraceSpaces, e.TicketsHeld, e.EventID, 0 AS OoDTickets, (IFNULL(t.Adults,0) + IFNULL(t.Children,0)) AS DTickets FROM TicketedPrograms p INNER JOIN TicketedEvents e ON p.ProgramID = e.ProgramID INNER JOIN TicketLocations l ON p.LocationID = l.LocationID INNER JOIN Tickets t ON e.EventID = t.EventID WHERE e.EventDate = ? AND ? BETWEEN DATE_SUB(p.ProgramTime, INTERVAL ' . $beforeminutes . ' MINUTE) AND DATE_ADD(p.ProgramTime, INTERVAL ' . $bufferminutes . ' MINUTE) AND t.DistrictResidentID > 5)) t GROUP BY EventID ORDER BY ProgramTime ASC;') or die &return_error("Could not prepare out of district query", $DBI::errstr);
$sth->execute($today, $time, $today, $time, $today, $time) or die &return_error("Could not execute out of district query", $DBI::errstr);

my @events;
while (my @row = $sth->fetchrow_array) {
    my $ages, $agequal;
    my $time = $row[1];
    my $program = $row[0];
    my $location = $row[3];
    if ($row[4] =~ /(\d+-\d+)([ym])/) {
        $ages = $1;
        $agequal = $2;
    }
    my $regdelay = $row[2];
    my $capacity = $row[5];
    my $gracespaces = $row[6];
    my $ticketsheld = $row[7];
    my $oodtickets = 0;
    my $dtickets = 0;
    if (defined($row[9])) {
        $oodtickets = $row[9];
    }
    if (defined($row[10])) {
        $dtickets = $row[10];
    }
    my $eventid = $row[8];
	my $eventinfo = "{\"program\": \"$program\", \"time\": \"$time\", \"registrationdelay\": $regdelay, \"location\": \"$location\", \"ages\": \"$ages\", \"age_qualifier\": \"$agequal\", \"capacity\": $capacity, \"grace\": $gracespaces, \"eventid\": \"$eventid\", \"oodtickets\": $oodtickets, \"dtickets\": $dtickets, \"ticketsheld\": $ticketsheld }";
}

$response .= "\"events\": [ ";
if (scalar @events > 0) {
    for (my $x = 0; $x < scalar @events; $x++) {
        if ($x > 0) {
            $response .= ", "
        }
        $response .= $events[$x];
    }
}
$response .= "], ";

$sth->finish();

$sth = $dbh->prepare(q{SELECT p.ProgramTime, COUNT(e.EventID) AS Total FROM TicketedEvents e INNER JOIN Tickets t ON e.EventID = t.EventID INNER JOIN TicketedPrograms p ON e.ProgramID = p.ProgramID WHERE e.EventDate = ? AND t.Identifier = UNHEX(?) GROUP BY p.ProgramTime}) or die &return_error("Could not get ticketed information for user.", $DBI::errstr);
$sth->execute($today, $hash) or die &return_error("Could not execute ticketed information search.", $DBI::errstr);

my $rawtest;

my @ticketlist;
while (my @row = $sth->fetchrow_array) {
    my $time = $row[0];
    my $ticketcount = $row[1];
    if ($ticketcount > 0) {
	    push(@ticketlist, $time);
    }
}

$response .= "\"tickets\": [ ";
if (scalar(@ticketlist) > 0) {
    for (my $x = 0; $x <= scalar(@tickets); $x++) {
        if ($x > 0) {
            $response .= ", "
        }
        $response .= "\"$ticketlist[$x]\"";
    }
}
$response .= " ] }";

print "Content-type: text/plain\n\n";
print $response;

sub append_checksum {
    my ($text) = @_;
    my $check = 0;
    foreach my $char (split //, $text) {
        $check += ord($char);
    }
    $check += ord("\0");
    $check = ($check ^ 0xFFFF) + 1;
    my $checksum = sprintf('%4.4X', $check);
    $text .= $checksum;
    return $text;
}

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{\"error\": \"$simple\", \"detail\": \"$detailed\"}";
    exit;
};
