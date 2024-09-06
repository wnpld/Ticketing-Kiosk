#!/usr/bin/perl
use DBI;
use CGI;
use Common;

#Database Variables
my ($user_name, $password, $dbh, $sth);
($user_name, $password) = ($Common::dbuser, $Common::dbpassword);
my $db_name = $Common::databasename;
my $dsn = "DBI:mysql:database=$db_name";
$dbh = DBI->connect($dsn, $user_name, $password, { RaiseError => 1} ) or die &return_error("Could not connect to database", $DBI::errstr);

#Get CGI values
my $q = CGI->new;
my $newadulttickets = $q->param('adults');
if ($newadulttickets !~ /^\d+$/) {
    #Not a number
    &return_error("Invalid Submission","The quantity for adult tickets was not a number.  If you don't know why this happened, report this error.");
}
my $newchildtickets = $q->param('children');
if ($newchildtickets !~ /^\d+$/) {
    #Not a number
    &return_error("Invalid Submission","The quanity for child tickets was not a number.  If you don't know why this happened, report this error.");
}



my $action = $q->param('action');
if ($action eq "extra") {
    my $ticketid = $q->param('ticketid');
    if ($ticketid =~ /^\d+$/) {
        $sth=$dbh->prepare("SELECT t.Adults, t.Children, te.TicketsHeld FROM Tickets t INNER JOIN TicketedEvents te ON t.EventID = te.EventID WHERE TicketID = ?") or die &return_error("SQL Error","Could not prepare existing ticket count query: " . $DBI::errstr);
        $sth->execute($ticketid) or die &return_error("SQL Error","Error executing existing ticket count query: " . $DBI::errstr);
        
        my ($oldadulttickets, $oldchildtickets, $held) = $sth->fetchrow_array;
        if (!defined($held)) {
            &return_error("Ticket ID Problem","Either the submitted ticket id was invalid or the event id associated with it is invalid.  If you do not know why this happened, please report this problem.");
        }
        my $childtickets = $newchildtickets + $oldchildtickets;
        my $adulttickets = $newadulttickets + $oldadulttickets;

        $sth=$dbh->prepare("UPDATE Tickets SET Adults = ?, Children = ? WHERE TicketID = ?") or die &return_error("SQL Error","Could not prepare exiting ticket update query: " . $DBI::errstr);
        $sth->execute($adulttickets, $childtickets, $ticketid) or die &return_error("SQL Error","Error executing existing ticket update query: " . $DBI::errstr);

        $held = $held - ($newchildtickets + $newadulttickets);
        if ($held < 0) {
            $held = 0;
        }

        $sth=$dbh->prepare("UPDATE TicketedEvents te INNER JOIN Tickets t ON t.EventID = te.EventID SET TicketsHeld = ? WHERE t.TicketID = ?") or die &return_error("SQL Error","Error preparing held tickets quantity: " . $DBI::errstr);
        $sth->execute($held, $ticketid) or die &return_error("SQL Error","Error executing held ticket quantity update: " . $DBI::errstr);


        print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/printtickets.php?ticketid=$ticketid&reprint=false&children=$newchildtickets&adults=$newadulttickets\n\n";
        exit;
    } else {
        #Invalid id
        &report_error("Invalid Ticket ID","The ticket id submitted was invalid.  Either this form was submitted using an out-of-date ticket list and the ticket had already been deleted, or some other error has occurred.  If you don't know why this happened, report this error.");
    }
} else {
    my $eventid = $q->param('eventid');

    if ($eventid !~ /^\d+$/) {
        &return_error("Invalid Information","The event id submitted for this ticket was not a number.  If you don't know why this happened, report this error.");
    }

    #Verify the eventid and get the number of held spaces
    $sth=$dbh->prepare("SELECT TicketsHeld FROM TicketedEvents WHERE EventID = ?") or die &return_error("SQL Error","Could not prepare event id lookup:" . $DBI::errstr);
    $sth->execute($eventid) or die &return_error("SQL Error","Could not execute event id lookup: " . $DBI::errstr);
    my $held = $sth->fetchrow_array;

    if (!defined($held)) {
        &return_error("Invalid Event","The event id submitted was not a valid event.  If you do not know why this happened, please report this error.");
    }

    #The field for ticket id storage is a 16 byte binary field which takes a 32 character
    #hexadecimal hash.  For staff tickets we are generating values which fit into this field
    #but are not hashes.  These count up from 01 to 99.  This is done by duplicating the number
    #including the zero, e.g. 01010101010101010101010101010101.  Each staff ticket for a given
    #event is given a different ID to make it easier to manage staff issued tickets if necessary.

    my $code = undef;
    my $counter = 0;
    while (!defined($code)) {
        $counter++;
        my $testcode = "";
        if ($counter < 10) {
            $testcode = "0" . $counter;
        } else {
            $testcode = $counter;
        }
        for (my $x = 0; $x < 4; $x++) {
            $testcode = $testcode . $testcode;
        }
        $sth=$dbh->prepare("SELECT TicketID FROM Tickets WHERE HEX(Identifier) = ? AND EventID = ?") or die &return_error("SQL Error","Could not prepare check for staff tickets:" . $DBI::errstr);
        $sth->execute($testcode, $eventid) or die &return_error("SQL Error", "Could not execute check for staff tickets: " . $DBI::errstr);
        my ($result) = $sth->fetchrow_array;
        if (!defined($result)) {
            #This is the result we want - no match
            $code = $testcode;
        }
    }

    #Now that we have a staff code, add tickets
    $sth=$dbh->prepare("INSERT INTO Tickets (EventID, Adults, Children, Identifier, DistrictResidentID) VALUES (?, ?, ?, UNHEX(?), 7)") or die &return_error("SQL Error","Could not prepare staff ticket insert: " . $DBI::errstr);
    $sth->execute($eventid, $newadulttickets, $newchildtickets, $code) or die &return_error("SQL Error", "Could not insert staff tickets: " . $DBI::errstr);
    my $ticketid = $dbh->last_insert_id();
    $sth->finish;

    #Finally, if there are held tickets, remove them from the event information
    $held = $held - ($newadulttickets + $newchildtickets);
    if ($held < 0) {
        #It's not necessary to have negative held tickets
        $held = 0;
    }

    $sth = $dbh->prepare("UPDATE TicketedEvents SET TicketsHeld = ? WHERE EventID = ?") or die &return_error("SQL Error","Error preparing held tickets update: " . $DBI::errstr);
    $sth->execute($held, $eventid) or die &return_error("SQL Error","Error executing held tickets update:" . $DBI::errstr);

    print "Location: " . $Common::serverprotocol . "://" . $Common::serveraddress . "/" . $Common::managementdir . "/printtickets.php?ticketid=$ticketid&reprint=false&children=$newchildtickets&adults=$newadulttickets\n\n";
    exit;
}

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{ \"status\": \"$simple\", \"detail\": \"$detailed\" }";
    exit;
};