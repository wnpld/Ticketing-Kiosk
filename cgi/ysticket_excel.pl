#!/usr/bin/perl
use strict;
use POSIX qw(strftime);
use CGI;
use DBI;
use Excel::Writer::XLSX;
use Common;

#Database Variables
my ($user_name, $password, $sth);
($user_name, $password) = ($Common::dbuser, $Common::dbpassword);
my $db_name = $Common::databasename;
my $dsn = "DBI:mysql:database=$db_name";

my $q = CGI->new;
my ($startdate, $enddate);
#Look for a passed date variable, otherwise assume the beginning of January 2025
if (defined($q->param('start'))) {
    if ($q->param('start') =~ /^20\d\d-[01]\d-[0123]\d$/) {
        $startdate = $q->param('start');
    } else {
        $startdate = "2025-01-01";
    }
} else {
    $startdate = "2025-01-01";
}

#Look for a passed end date variable, otherwise assume today
if (defined($q->param('end'))) {
    if ($q->param('end') =~ /^20\d\d-[01]\d-[0123]\d$/) {
        $enddate = $q->param('end');
    } else {
        $enddate = strftime "%F", localtime;
    }
} else {
    $enddate = strftime "%F", localtime;
}

my $filename = "ticket_data_" . $startdate . "_" . $enddate;

#Archived determines if archived programs show up in the report
#Default is not to include them.
if (defined($q->param('archived'))) {
    if ($q->param('archived') =~ /^\d$/) {
        $archived = $q->param('archived');
    } else {
        $archived = 0;
    }
} else {
    $archived = 0;
}

$dbh = DBI->connect($dsn, $user_name, $password, { RaiseError => 1} ) or die &return_error("Could not connect to database", $DBI::errstr);

$sth = $dbh->prepare("SELECT ProgramName, ProgramTime, ProgramDate, ProgramAges, SUM(WinnetkaAdults) AS WinnetkaAdults, SUM(WinnetkaChildren) AS WinnetkaChildren, SUM(NorthfieldAdults) AS NorthfieldAdults, SUM(NorthfieldChildren) AS NorthfieldChildren, SUM(AreaAdults) AS AreaAdults, SUM(AreaChildren) AS AreaChildren, SUM(UnknownAdults) AS OtherAdults, SUM(UnknownChildren) AS OtherChildren FROM ((SELECT tp.ProgramName, tp.ProgramTime, te.EventDate AS ProgramDate, tp.AgeRange AS ProgramAges, SUM(t.Adults) AS WinnetkaAdults, SUM(t.Children) AS WinnetkaChildren, 0 AS NorthfieldAdults, 0 AS NorthfieldChildren, 0 AS AreaAdults, 0 AS AreaChildren, 0 AS UnknownAdults, 0 AS UnknownChildren FROM TicketedPrograms tp INNER JOIN TicketedEvents te ON tp.ProgramID = te.ProgramID INNER JOIN Tickets t ON te.EventID = t.EventID INNER JOIN Districts d ON t.DistrictResidentID = d.DistrictID WHERE d.DistrictName = 'WNPLD (Winnetka)' AND tp.Archived <= ? AND te.EventDate BETWEEN ? AND ? GROUP BY tp.ProgramName, te.EventDate, tp.ProgramTime) UNION ALL (SELECT tp.ProgramName, tp.ProgramTime, te.EventDate AS ProgramDate, tp.AgeRange AS ProgramAges, 0 AS WinnetkaAdults, 0 AS WinnetkaChildren, SUM(t.Adults) AS NorthfieldAdults, SUM(t.Children) AS NorthfieldChildren, 0 AS AreaAdults, 0 AS AreaChildren, 0 AS UnknownAdults, 0 AS UnknownChildren FROM TicketedPrograms tp INNER JOIN TicketedEvents te ON tp.ProgramID = te.ProgramID INNER JOIN Tickets t ON te.EventID = t.EventID INNER JOIN Districts d ON t.DistrictResidentID = d.DistrictID WHERE d.DistrictName = 'WNPLD (Northfield)' AND tp.Archived <= ? AND te.EventDate BETWEEN ? AND ? GROUP BY tp.ProgramName, te.EventDate, tp.ProgramTime) UNION ALL (SELECT tp.ProgramName, tp.ProgramTime, te.EventDate AS ProgramDate, tp.AgeRange AS ProgramAges, 0 AS WinnetkaAdults, 0 AS WinnetkaChildren, 0 AS NorthfieldAdults, 0 AS NorthfieldChildren, SUM(t.Adults) AS AreaAdults, SUM(t.Children) AS AreaChildren, 0 AS UnknownAdults, 0 AS UnknownChildren FROM TicketedPrograms tp INNER JOIN TicketedEvents te ON tp.ProgramID = te.ProgramID INNER JOIN Tickets t ON te.EventID = t.EventID INNER JOIN Districts d ON t.DistrictResidentID = d.DistrictID WHERE (d.DistrictName = 'Evanston' OR d.DistrictName = 'Wilmette' OR d.DistrictName = 'Glencoe' OR d.DistrictName = 'Northbrook' OR d.DistrictName = 'Glenview') AND tp.Archived <= ? AND te.EventDate BETWEEN ? AND ? GROUP BY tp.ProgramName, te.EventDate, tp.ProgramTime) UNION ALL (SELECT tp.ProgramName, tp.ProgramTime, te.EventDate AS ProgramDate, tp.AgeRange AS ProgramAges, 0 AS WinnetkaAdults, 0 AS WinnetkaChildren, 0 AS NorthfieldAdults, 0 AS NorthfieldChildren, 0 AS AreaAdults, 0 AS AreaChildren, SUM(t.Adults) AS UnknownAdults, SUM(t.Children) AS UnknownChildren FROM TicketedPrograms tp INNER JOIN TicketedEvents te ON tp.ProgramID = te.ProgramID INNER JOIN Tickets t ON te.EventID = t.EventID INNER JOIN Districts d ON t.DistrictResidentID = d.DistrictID WHERE d.DistrictName = 'Other' AND tp.Archived <= ? AND te.EventDate BETWEEN ? AND ? GROUP BY tp.ProgramName, te.EventDate, tp.ProgramTime)) t GROUP BY ProgramName, ProgramDate, ProgramTime ORDER BY ProgramDate, ProgramTime") or die &return_error("Database Error", "Error preparing query: " . $DBI::errstr);

$sth->execute($archived, $startdate, $enddate, $archived, $startdate, $enddate, $archived, $startdate, $enddate, $archived, $startdate, $enddate) or die &return_error("Database Error", "Error executing query: " . $DBI::errstr);

my $rows = $sth->rows;

open my $excelfh, '>', \my $output or die "Failed to open filehandle: $!";

my $workbook = Excel::Writer::XLSX->new( $excelfh );
my %sheets = ();
my %sheet_names = (
    1 => "Programs!",
);
$sheets{1} = $workbook->add_worksheet( 'Programs' );

$sheets{1}->set_column(0,0,20);
$sheets{1}->set_column(1,3,10);
$sheets{1}->set_column(4,7,20);
$sheets{1}->set_column(8,15,15);

my $totalFormat = $workbook->add_format();
$totalFormat->set_italic();
$totalFormat->set_bold();

my $y = 0;
my $x = 0;
my ($totalAdults, $totalChildren);

while (my $row = $sth->fetchrow_hashref()) {
    $y++;
    $x = 0;
    $sheets{1}->write($y, $x, $row->{'ProgramName'});
    $x++;
    $sheets{1}->write($y, $x, $row->{'ProgramAges'});
    $x++;
    $sheets{1}->write($y, $x, $row->{'ProgramDate'});
    $x++;
    my @timebits = split(':', $row->{'ProgramTime'});
    my $nicetime;
    #format the time pretty -- could do this in the SQL query but it's crazy long already
    if ($timebits[0] > 12) {
        $nicetime = "0" . ($timebits[0] - 12) . ":" . $timebits[1] . " p.m.";
    } elsif ($timebits[0] == 12) {
        $nicetime = "12:" . $timebits[1] . " p.m.";
    } else {
        $nicetime = $timebits[0] . ":" . $timebits[1] . " a.m.";
    }
    $sheets{1}->write($y, $x, $nicetime);
    $x++;
    $totalAdults = 0;
    $totalChildren = 0;
    $sheets{1}->write($y, $x, $row->{'WinnetkaAdults'});
    $totalAdults += $row->{'WinnetkaAdults'};
    $x++;
    $sheets{1}->write($y, $x, $row->{'WinnetkaChildren'});
    $totalChildren += $row->{'WinnetkaChildren'};
    $x++;
    $sheets{1}->write($y, $x, $row->{'NorthfieldAdults'});
    $totalAdults += $row->{'NorthfieldAdults'};
    $x++;
    $sheets{1}->write($y, $x, $row->{'NorthfieldChildren'});
    $totalChildren += $row->{'NorthfieldChildren'};
    $x++;
    $sheets{1}->write($y, $x, $totalAdults, $totalFormat);
    $x++;
    $sheets{1}->write($y, $x, $totalChildren, $totalFormat);
    $x++;
    $sheets{1}->write($y, $x, $row->{'AreaAdults'});
    $totalAdults += $row->{'AreaAdults'};
    $x++;
    $sheets{1}->write($y, $x, $row->{'AreaChildren'});
    $totalChildren += $row->{'AreaChildren'};
    $x++;
    $sheets{1}->write($y, $x, $row->{'OtherAdults'});
    $totalAdults += $row->{'OtherAdults'};
    $x++;
    $sheets{1}->write($y, $x, $row->{'OtherChildren'});
    $totalChildren += $row->{'OtherChildren'};
    $x++;
    $sheets{1}->write($y, $x, $totalAdults, $totalFormat);
    $x++;
    $sheets{1}->write($y, $x, $totalChildren, $totalFormat);
}
$dbh->disconnect;

if ($rows > 0) {
    $sheets{1}->add_table(
        0,0,$rows,15, 
        { 
            style => 'Table Style Medium 2', 
            name => 'AttendanceData',
            columns => [
                {header => 'Program'},
                {header => 'Age Range'},
                {header => 'Date'},
                {header => 'Time'},
                {header => 'Winnetka Adults'},
                {header => 'Winnetka Children'},
                {header => 'Northfield Adults'},
                {header => 'Northfield Children'},
                {header => 'District Adults'},
                {header => 'District Children'},
                {header => 'Area Adults'},
                {header => 'Area Children'},
                {header => 'Other Adults'},
                {header => 'Other Children'},
                {header => 'Total Adults'},
                {header => 'Total Children'},
            ]
        });
} else {
    $sheets{1}->write(0,0,'No data found.');
}

$workbook->close();
use bytes;
my $byte_size = length($output);
print "Content-length: $byte_size\n";
print "Content-type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet\n";
print "Content-Disposition:attachment;filename=" . $filename . ".xlsx\n\n";
binmode STDOUT;
print $output;

exit 0;

sub return_error {
    my ($simple, $detailed) = @_;
    print "Content-type: text/plain\n\n";
    print "{\"error\": \"$simple\", \"detail\": \"$detailed\"}";
    exit;
};
