#!/usr/bin/perl
use DBI;
use CGI;
use Data::Dumper;
use Common;

#Database Variables
#Update these variable for your implementation
my ($user_name, $password, $dbh, $sth);
($user_name, $password) = ($Common::dbuser, $Common::dbpassword);
my $db_name = $Common::databasename;
my $dsn = "DBI:mysql:database=$db_name";
$dbh = DBI->connect($dsn, $user_name, $password, { RaiseError => 1} ) or die &return_error("Could not connect to database", $DBI::errstr);

#Get CGI values
my $q = CGI->new;
my $programid = $q->param('ProgramID');
if (!defined($programid)) {
    #With no program id this has to be a request to delete events
    my @events = $q->param('EventID');
    $sth = $dbh->prepare('DELETE FROM TicketedEvents WHERE EventID = ?') or die &return_error("SQL Error", "Could not prepare query to delete events: " . $DBI::errstr);
    foreach my $event (@events) {
        if ($event =~ /^\d+$/) {
            $sth->execute($event) or die &return_error("SQL Error","Could not delete event: " . $DBI::errstr);
        }
    }
    $sth->finish;
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/calendar.php\n\n";
    exit;
} else {
    #Get the default held number from the program information
    my @dates = $q->param('EventDate');
    $sth = $dbh->prepare('INSERT INTO TicketedEvents (ProgramID, EventDate, TicketsHeld) VALUES (?, ?, (SELECT DefaultHeld FROM TicketedPrograms WHERE ProgramID = ?))') or die &return_error("SQL Error", "Could not prepare query to add events: " . $DBI::errstr);
    if ($programid =~ /^\d+$/) {
        foreach my $date (@dates) {
            if ($date =~ /^\d{4}-\d{2}-\d{2}$/) {
                $sth->execute($programid, $date, $programid) or die &return_error("SQL Error", "Could not execute addition of event: " . $DBI::errstr);
            }
        }
        $sth->finish;
    }
    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/calendar.php\n\n";
    exit;
}

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{ \"status\": \"$simple\", \"detail\": \"$detailed\" }";
    exit;
};