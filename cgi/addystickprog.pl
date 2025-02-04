#!/usr/bin/perl
use DBI;
use CGI;
use Data::Dumper;
use Common;

#Database Variables
my ($user_name, $password, $sth);
($user_name, $password) = ($Common::dbuser, $Common::dbpassword);
my $db_name = $Common::databasename;
my $dsn = "DBI:mysql:database=$db_name";

#Get CGI values
my $q = CGI->new;
my %invalids; #Except for ProgramID (which get a separate check) and invalid values are put into here
my $programid = $q->param('ProgramID');
my $action = $q->param('action');

my ($programname, $programhours, $programminutes, $time, $daylist, $lowage, $highage, $monthsyears, $agerange, $secondtierminutes, $locationid, $defaultheld, $capacity, $grace, $childonly);
my @days;

if (!defined($action)) {
    $programname = $q->param('ProgramName');
    if ($programname !~ /^[0-9A-Za-z' ()&?!]+$/) {
        $invalids{'ProgramName'} = $programname;
    }
    $programhours = $q->param('ProgramHours');
    if (($programhours !~ /^\d{1,2}$/) || (($programhours < 9) || ($programhours > 20))) {
        $invalids{'ProgramHours'} = $programhours;
    }
    $programminutes = $q->param('ProgramMinutes');
    if ($programminutes !~ /^[0134][05]$/) {
        $invalids{'ProgramMinutes'} = $programminutes;
    }
    $time = "$programhours:$programminutes:00";
    @days = $q->param('Days');
    if (scalar @days < 1) {
        $invalids{'Days'} = "No days";
    }
    foreach my $testday (@days) {
        if ($testday !~ /Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday/) { 
            if (defined($invalids{'Days'})) {
                $invalids{'Days'} .= "," . $testday;
            } else {
                $invalids{'Days'} = $testday;
            }
        } else {
            if (!defined($daylist)) {
                $daylist = $testday;
            } else {
                $daylist .= ",$testday";
            }
        }
    }
    $lowage = $q->param('LowAge');
    if ($lowage !~ /^\d{1,2}$/) {
        $invalids{'LowAge'} = $lowage;
    }
    $highage = $q->param('HighAge');
    if ($highage !~ /^\d{1,2}$/) {
        $invalids{'HighAge'} = $highage;
    }
    $monthsyears = $q->param('MonthsYears');
    #binary options, so if not one choose the other
    if ($monthsyears ne "m") {
        $monthsyears = "y";
    }
    $agerange = $lowage . "-" . $highage . $monthsyears;
    $secondtierminutes = $q->param('SecondTierMinutes');
    if ($secondtierminutes !~ /^\d+$/) {
        $invalids{'SecondTierMinutes'} = $secondtierminutes;
    }
    $locationid = $q->param('LocationID');
    if ($locationid !~ /^\d+$/) {
        #Only checking to see if it's a number, not if it's a valid id.
        #An invalid id will trigger a SQL error but it won't do anything bad
        #to the database.
        $invalids{'LocationID'} = $locationid;
    }
    $defaultheld = $q->param('DefaultHeld');
    if ($defaultheld !~ /^\d+$/) {
        $invalids{'DefaultHeld'} = $defaultheld;
    }
    $capacity = $q->param('Capacity');
    if ($capacity !~ /^\d+$/) {
        $invalids{'Capacity'} = $capacity;
    }
    $grace = $q->param('Grace');
    if ($grace !~ /^\d+$/) {
        $invalids{'Grace'} = $grace;
    }
    $childonly = $q->param('ChildOnly');
    if ($childonly !~ /^1$/) {
        #This is a binary value so no need to worry about it being invalid.  Either it is set or it isn't
        $childonly = 0;
    }
}

if (keys %invalids > 0) {
    print "Content-type:text/plain\n\n";
    print "The following fields contained invalid data:\n";
    print Dumper(%invalids);
    exit;
}

#If ProgramID is numeric, this is an update
if ($programid =~ /^\d+$/) {
    #If action is defined, this is either a delete or archive situation
    #It's unecessary to worry about any fields other than action and ProgramID
    if (defined($action)) {
        if ($action eq "archive") {
            $sth=$dbh->prepare("UPDATE TicketedPrograms SET Archived = 1 WHERE ProgramID = ?") or die &return_error("SQL Error","Could not prepare archive update:" . $DBI::errstr);
            $sth->execute($programid) or die &return_error("SQL Error","Could not execute archive update: " . $DBI::errstr);
            print "Location: $Common::$serverprotocol://$Common::$serveraddress/$Common::$managementdir/programs.php\n\n";
            exit;
        } elsif ($action eq "delete") {
            $sth=$dbh->prepare("DELETE FROM TicketedPrograms WHERE ProgramID = ?") or die &return_error("SQL Error","Could not prepare program deletion: " . $DBI::errstr);
            $sth->execute($programid) or die &return_error("SQL Error","Could not execute program deletion: " . $DBI::errstr);
            print "Location: $Common::$serverprotocol://$Common::$serveraddress/$Common::$managementdir/programs.php\n\n";
            exit;
        } else {
            #This is weird so just redirect backd
            print "Location: $Common::$serverprotocol://$Common::$serveraddress/$Common::$managementdir/programs.php\n\n";
            exit;
        }
    } else {
        #Otherwise this is a record update
        $sth=$dbh->prepare("UPDATE TicketedPrograms SET ProgramName = ?, ProgramTime = ?, ProgramDays = ?, AgeRange = ?, SecondTierMinutes = ?, LocationID = ?, DefaultHeld = ?, Capacity = ?, Grace = ?, ChildOnly = ? WHERE ProgramID = ?") or die &return_error("SQL Error", "Error preparing program update: " . $DBI::errstr);
        $sth->execute($programname, $time, $daylist, $agerange, $secondtierminutes, $locationid, $defaultheld, $capacity, $grace, $childonly, $programid) or die &return_error("SQL Error", "Error executing program update: " . $DBI::errstr);
        print "Location: $Common::$serverprotocol://$Common::$serveraddress/$Common::$managementdir/programs.php\n\n";
        exit;
    }
} else {
    #If ProgramID is not numeric, we'll assume it's the word "new" and is an insert
    $sth=$dbh->prepare("INSERT INTO TicketedPrograms (ProgramName, ProgramTime, ProgramDays, AgeRange, SecondTierMinutes, LocationID, DefaultHeld, Capacity, Grace, ChildOnly) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)") or die &return_error("SQL Error","Error preparing program addition: " . $DBI::errstr);
    $sth->execute($programname, $time, $daylist, $agerange, $secondtierminutes, $locationid, $defaultheld, $capacity, $grace, $childonly) or die &return_error("SQL Error", "Error executing program addition: " . $DBI::errstr);
    print "Location: $Common::$serverprotocol://$Common::$serveraddress/$Common::$managementdir/programs.php\n\n";
    exit;
}

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{ \"status\": \"$simple\", \"detail\": \"$detailed\" }";
    exit;
};