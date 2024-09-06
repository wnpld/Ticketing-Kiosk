#!/usr/bin/perl
use DBI;
use CGI;
use Common;

#Adjustable variables
#ticketmax is the maximum tickets of a type that can be acquired
my $ticketmax = 2;

#List of languages
my @languages = ('english', 'spanish', 'polish', 'russian', 'chinese', 'tradchinese');

#Database Variables
my ($user_name, $password, $sth);
($user_name, $password) = ($Common::dbuser, $Common::dbpassword);
my $db_name = $Common::databasename;
my $dsn = "DBI:mysql:database=$db_name";

#Get CGI values
my $q = CGI->new;
my $adulttickets = $q->param('adult');
my $childtickets = $q->param('child');

#troubleshooting
#$adulttickets = 1;
#$childtickets = 2;

#Adult & Child tickets need to be checked to make sure that they make sense
if (($adulttickets =~ /^\d+$/) && ($childtickets =~ /^\d+/)) {
    if (($adulttickets < 1) || ($adulttickets > $ticketmax)) {
        $adulttickets = undef;
    }
    if (($childtickets < 1) || ($childtickets > $ticketmax)) {
        $childtickets = undef;
    }
} else {
    $adulttickets = undef;
    $childtickets = undef;
}

#Make sure id looks right
my $id = $q->param('identifier');

#troubleshooting
#$id = "21240000639655";

if ($id !~ /^[0-9a-f]+$/) {
    $id = undef;
}

my $library = $q->param('library');

#troubleshooting
#$library = 7;

#library needs to be checked to make sure it's in the right range
if ($library =~ /^\d+$/) {
    if ($library >= 9) {
        $library = $library - 9;
    } else {
        $library = $library - 1;
    }
} else {
    $library = undef;
}

my $eventid = $q->param('event');

#troubleshooting
#$eventid = 2;

if ($eventid !~ /^\d+$/) {
    $eventid = undef;
}

my $language = $q->param('language');

#troubleshooting
#$language = "english";

my $found = 0;
if ($language =~ /^[a-z]+$/) {
    foreach my $langname (@languages) {
        if ($language eq $langname) {
            $found = 1;
        }
    }
    if ($found == 0) {
        $language = undef;
    }
} else {
    $language = undef;
}

##If any variable failed a check, return a failure message
#otherwise, add them to the database.

if (defined($adulttickets) && defined($childtickets) && defined($id) && defined($library) && defined($eventid) && defined($language)) {
    my $dbh = DBI->connect($dsn, $user_name, $password, { RaiseError => 1} ) or die &return_error("Could not connect to database", $DBI::errstr);
    $sth = $dbh->prepare(q{INSERT INTO Tickets (EventID, Adults, Children, Identifier, DistrictResidentID, Language) VALUES (?, ?, ?, UNHEX(?), ?, ?)}) or die &return_error("Error preparing ticket insert query.", $DBI::errstr);
    $sth->execute($eventid, $adulttickets, $childtickets, $id, $library, $language) or die &return_error("Error executing ticket query.", $DBI::errstr);
    print "Content-type: text/plain\n\n";
    print "{ \"status\": \"success\" }";
    exit;
} else {
    print "Content-type: text/plain\n\n";
    print "{ \"status\": \"Error - At least one value sent for processing not valid.\" }";
    exit;
}

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{ \"status\": \"$simple\", \"detail\": \"$detailed\" }";
    exit;
};
