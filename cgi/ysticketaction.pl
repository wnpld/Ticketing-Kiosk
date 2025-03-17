#!/usr/bin/perl
use CGI;
use DBI;
use Common;

#Database Variables
my ($user_name, $password, $dbh, $sth);
($user_name, $password) = ($Common::dbuser, $Common::dbpassword);
my $db_name = $Common::databasename;
my $dsn = "DBI:mysql:database=$db_name";

my $q = CGI->new;
my ($scope, $id, $childcount, $adultcount, $eventid);
$id = $q->param('id');

if (!defined($q->param('TicketId')) || !defined($q->param('Scope')) || !defined($q->param('EventId')) || !defined($q->param('ChildCount')) || !defined($q->param('AdultCount'))) {
    #Something's very wrong.  Leave.
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/\n\n";
    exit;
}

if ($q->param('EventId') =~ /^\d+$/) {
    $eventid = $q->param('EventId');
} else {
    #Invalid Event ID. Leave
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/\n\n";
    exit;
}

if ($q->param('TicketId') =~ /^\d+$/) {
    $id = $q->param('TicketId');
} else {
    #Invalid ID. Leave
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/eventinfo.php?eventid=$eventid\n\n";
    exit;
}

if ($q->param('Scope') =~ /^[a-z]{3,5}$/) {
    $scope = $q->param('Scope');
} else {
    #Invalid scope, assume entire ticket being cancelled
    $scope == "all";
}

if ($scope ne "all") {
    if ($scope eq "adult") {
        if ($q->param('AdultCount') =~ /^\d+$/) {
            $adultcount = $q->param('AdultCount');
            if ($adultcount < 1) {
                #This value makes no sense as a starting point for reducing adult tickets
                #Switch to just deleting all tickets
                $scope = "all";
            }
        }
    } elsif ($scope eq "child") {
        if ($q->param('ChildCount') =~ /^\d+$/) {
            $childcount = $q->param('ChildCount');
            if ($childcount <= 1) {
                #This value makes no sense as a starting point for reducing child tickets
                #Switch to just deleting all tickets
                $scope = "all";
            }
        }
    } else {
        #Child and Adult are the only valid values other than All.  Switch to all.
        $scope = "all";
    }
}

$dbh = DBI->connect($dsn, $user_name, $password, { RaiseError => 1} ) or die &return_error("Could not connect to database: ", $DBI::errstr);

if ($scope eq "all") {
    #Delete ticket record
    $sth=$dbh->prepare('DELETE FROM Tickets WHERE TicketID = ?') or die &return_error("SQL Error", "Error preparing ticket deletion: ", $DBI::errstr);
    $sth->execute($id) or die &return_error("SQL Error", "Error deleting tickets: ", $DBI::errstr);
} else {
    #Update ticket record with new ticket total for children or adults
    my ($group, $newtickets);
    if ($scope eq "child") {
        $group = "Children";
        $newtickets = $childcount - 1;
    } else {
        $group = "Adults";
        $newtickets = $adultcount - 1;
    }
    $sth=$dbh->prepare('UPDATE Tickets SET ' . $group . ' = ' . $newtickets . ' WHERE TicketID = ?') or die &return_error("SQL Error", "Error preparing update query to reduce ticket count: " . $DBI::errstr);
    $sth->execute($id) or die &return_error("SQL Error", "Error running update query to reduce ticket count: " . $DBI::errstr);
}

print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/eventinfo.php?eventid=$eventid\n\n";
exit;

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{\"error\": \"$simple\", \"detail\": \"$detailed\"}";
    exit;
};
