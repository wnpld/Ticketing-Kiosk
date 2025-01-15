#!/usr/bin/perl
use DBI;
use CGI;
use Common;
use Try::Tiny;

#Adjustable variables
#ticketmax is the maximum tickets of a type that can be acquired
my $aticketmax = 2; #Adult Tickets
my $jticketmax = 3; #Child Tickets

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

#Variable for total tickets -- needed to pull from held total for in-district requests
my $tickettotal = 0;

#troubleshooting
#$adulttickets = 1;
#$childtickets = 2;

#Adult & Child tickets need to be checked to make sure that they make sense
if (($adulttickets =~ /^\d+$/) && ($childtickets =~ /^\d+/)) {
    if (($adulttickets < 1) || ($adulttickets > $aticketmax)) {
        $adulttickets = undef;
    } else {
        $tickettotal += $adulttickets;
    }
    if (($childtickets < 1) || ($childtickets > $jticketmax)) {
        $childtickets = undef;
    } else {
        $tickettotal += $childtickets;
    }
} else {
    $adulttickets = undef;
    $childtickets = undef;
}

#Make sure id looks right
my $id = $q->param('identifier');

if ($id !~ /^[0-9a-f]+$/) {
    $id = undef;
}

my $library = $q->param('library');

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

#Add tickets to database.  Originally the held count was decreased, but this is unnecessary as it can 
#be counted on the fly based on district library.

if (defined($adulttickets) && defined($childtickets) && defined($id) && defined($library) && defined($eventid) && defined($language)) {
    #This returns a JSON block which needs to be interpreted by the patron machine, making error reporting
    #particularly dicey.  We're using a try/catch to make sure that unformatted errors don't slip through
    try {
        my $dbh = DBI->connect($dsn, $user_name, $password, { PrintError => 0, RaiseError => 1} );
        try {
            $sth = $dbh->prepare(q{INSERT INTO Tickets (EventID, Adults, Children, Identifier, DistrictResidentID, Language) VALUES (?, ?, ?, UNHEX(?), ?, ?)});
            try {
                $sth->execute($eventid, $adulttickets, $childtickets, $id, $library, $language);
                print "Content-type: text/plain\n\n";
                print "{ \"status\": \"success\" }";
            } catch {
                &return_error("Error", $_);
            } finally {
                exit;
            }
        } catch {
            &return_error("Error", $_);
            exit;
        }
    } catch {
        &return_error("Error", $_);
        exit;
    }
} else {
    &return_error("Error", "At least one value sent for processing not valid.");
    exit;
}

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{ \"status\": \"$simple\", \"detail\": \"$detailed\" }";
};
