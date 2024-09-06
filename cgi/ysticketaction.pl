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
my ($id, $query, $eventid);
$id = $q->param('id');

if (!defined($q->param('id')) || !defined($q->param('action')) || !defined($q->param('eventid'))) {
    #Something's very wrong.  Leave.
    print "Content-type: text/plain\n\n";
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/\n\n";
    exit;
}

if ($q->param('eventid') =~ /^\d+$/) {
    $eventid = $q->param('eventid');
} else {
    #Invalid Event ID. Leave
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/\n\n";
    exit;
}

if ($q->param('id') =~ /^\d+$/) {
    $id = $q->param('id');
} else {
    #Invalid ID. Leave
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/eventinfo.php?eventid=$eventid\n\n";
    exit;
}

$dbh = DBI->connect($dsn, $user_name, $password, { RaiseError => 1} ) or die &return_error("Could not connect to database", $DBI::errstr);

if ($q->param('action') eq "hold") {
    #get ticket quantity - we're adding tickets for the canceled order to the current held
    #quantity for a new total
    $sth=$dbh->prepare('SELECT (t.Adults + t.Children + e.TicketsHeld) AS Tickets FROM Tickets t INNER JOIN TicketedEvents e ON t.EventID = e.EventID WHERE t.TicketID = ?') or die &return_error("SQL Error", "Error preparing ticket total query: " . $DBI::errstr);
    $sth->execute($id) or die &return_error("SQL Error","Error getting ticket total: " . $DBI::errstr);
    my ($tickets) = $sth->fetchrow_array;

    #Add ticket quantity to the held total
    $sth=$dbh->prepare('UPDATE TicketedEvents e INNER JOIN Tickets t ON e.EventID = t.EventID SET e.TicketsHeld = ? WHERE t.TicketID = ?') or die &return_error("SQL Error", "Error preparing event update statement: " . $DBI::errstr);
    $sth->execute($tickets, $id) or die &return_error("SQL Error", "Error updating event record: " . $DBI::errstr);

}
#If there's no hold the ticket record can just be deleted

#Delete ticket record
$sth=$dbh->prepare('DELETE FROM Tickets WHERE TicketID = ?') or die &return_error("SQL Error", "Error preparing ticket deletion.");
$sth->execute($id);

print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/eventinfo.php?eventid=$eventid\n\n";
exit;

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{\"error\": \"$simple\", \"detail\": \"$detailed\"}";
    exit;
};
