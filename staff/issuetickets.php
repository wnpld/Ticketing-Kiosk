<?php
require_once('Connections/ticketingdb.php');

mysqli_select_db($ticketingdb, $database_ticketingdb);

$action = "";
$ticketid = 0;
$eventid = 0;
if (isset($_REQUEST['ticketid'])) {
    #We're adding extra tickets
    if (!is_numeric($_REQUEST['ticketid'])) {
        #Invalid ID
        header("Location: $protocol://$domain/$currentdir/\n\n");
        exit;
    } else {
        $action = "extra";
        $ticketid = $_REQUEST['ticketid'];
    }
    $query_tickettotal = $ticketingdb->prepare("SELECT ReservedTickets, AllTickets, GraceTickets, SUM(DistrictTickets) AS DistrictTickets, SUM(OODTickets) AS OODTickets, CurrentDistrict FROM ((SELECT tp.DefaultHeld AS ReservedTickets, tp.Capacity AS AllTickets, tp.Grace AS GraceTickets, (SUM(IFNULL(t.Adults, 0)) + SUM(IFNULL(t.Children, 0))) AS DistrictTickets, 0 AS OODTickets, (SELECT DistrictResidentID FROM Tickets WHERE TicketID = ?) AS CurrentDistrict FROM Tickets t INNER JOIN TicketedEvents te ON t.EventID = te.EventID INNER JOIN TicketedPrograms tp ON te.ProgramID = tp.ProgramID WHERE te.EventID = (SELECT EventID FROM Tickets WHERE TicketID = ?) AND (t.DistrictResidentID >= 6 OR t.DistrictResidentID IS NULL)) UNION ALL (SELECT tp.DefaultHeld AS ReservedTickets, tp.Capacity AS AllTickets, tp.Grace AS GraceTickets, 0 AS DistrictTickets, (SUM(IFNULL(t.Adults, 0)) + SUM(IFNULL(t.Children, 0))) AS OODTickets, (SELECT DistrictResidentID FROM Tickets WHERE TicketID = ?) AS CurrentDistrict FROM Tickets t INNER JOIN TicketedEvents te ON t.EventID = te.EventID INNER JOIN TicketedPrograms tp ON te.ProgramID = tp.ProgramID WHERE te.EventID = (SELECT EventID FROM Tickets WHERE TicketID = ?) AND (t.DistrictResidentID <= 5 OR t.DistrictResidentID IS NULL))) t");
    $query_tickettotal->bind_param('iiii', $ticketid, $ticketid, $ticketid, $ticketid);
    $query_tickettotal->execute() or die(mysqli_error($ticketingdb));
    $tickettotal = $query_tickettotal->get_result();
    $ticketstates = mysqli_fetch_assoc($tickettotal);
    $reserved = $ticketstates['ReservedTickets'];
    $alltickets = $ticketstates['AllTickets'];
    $grace = $ticketstates['GraceTickets'];
    $district = $ticketstates['DistrictTickets'];
    $ood = $ticketstates['OODTickets'];
    $current = $ticketstates['CurrentDistrict'];
    $taken = $district + $ood;
    if ($current <= 5) {
      #Out of District
      $available = $alltickets - ($reserved + $ood);
    } else {
      $available = $alltickets - $taken;
    }
} else if (isset($_REQUEST['eventid'])) {
    #We're issuing new tickets from the staff interface
    if (!is_numeric($_REQUEST['eventid'])) {
        #Invalid ID
        header("Location: $protocol://$domain/$currentdir/\n\n");
        exit; 
    } else {
        $action = "new";
        $eventid = $_REQUEST['eventid'];
    }
    $query_tickettotal = $ticketingdb->prepare("SELECT tp.DefaultHeld AS ReservedTickets, tp.Capacity AS AllTickets, tp.Grace AS GraceTickets, (SUM(IFNULL(t.Adults,0)) + SUM(IFNULL(t.Children,0))) AS AcquiredTickets FROM TicketedEvents te INNER JOIN TicketedPrograms tp ON te.ProgramID = tp.ProgramID INNER JOIN Tickets t ON te.EventID = t.EventID WHERE te.EventID = ?");
    $query_tickettotal->bind_param('i', $eventid);
    $query_tickettotal->execute() or die(mysqli_error($ticketingdb));
    $tickettotal = $query_tickettotal->get_result();
    $ticketstates = mysqli_fetch_assoc($tickettotal);
    $reserved = $ticketstates['ReservedTickets'];
    $alltickets = $ticketstates['AllTickets'];
    $grace = $ticketstates['GraceTickets'];
    $taken = $ticketstates['AcquiredTickets'];
    $current = 7;
    $available = $alltickets - $taken;
} else {
    #Something's wrong.  Redirect
    header("Location: $protocol://$domain/$currentdir/\n\n");
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Event Tickets</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
    <script>
      function verify_count() {
        var reserved = <?php echo $reserved; ?>;
        var alltickets = <?php echo $alltickets; ?>;
        var grace = <?php echo $grace; ?>;
        var taken = <?php echo $taken; ?>;
        var current = <?php echo $current; ?>;
        var available = <?php echo $available; ?>;
        var adults = Number(document.getElementById("adults").value);
        var children = Number(document.getElementById("children").value);
        var requested = adults+children;
        if (available >= requested) {
          //No Problems here
          if (current >= 6) {
            return confirm("This order will use " + requested + " tickets which will come out of the in-district reserved pool of tickets.");
          } else {
            return confirm("This order will use " + requested + " tickets which will come out of the general pool as the patron is out of district.")
          }
        } else if ((available + grace) >= requested) {
          if (current >= 6) {
            return confirm("This order will use " + requested + " tickets which will come out of the in-district reserved pool.  Grace tickets will also be used.");
          } else {
            return confirm("This order will use " + requested + " tickets which will come out of the general pool as the patron is out of district.  Grace tickets will also needed to fulfil this request.");
          }
        } else {
          if (current <= 5) {
            if ((alltickets - taken) > requested) {
              return confirm("This user is not confirmed as in district and only in district tickets remain.  Are you sure you want to take " + requested + " tickets out of the remaining tickets for this patron?");
            } else if (((alltickets + grace) - taken) < requested) {
              var deficit = Math.abs((alltickets + grace) - (taken + requested));
              return confirm("Issuing this ticket will take the room over capacity by " + deficit + " for a user not confirmed as in district.  Are you sure you want to do issue " + requested + " more tickets to this patron?");
            }
          } else {
            var deficit = Math.abs((alltickets + grace) - (taken + requested));
            return confirm("Issuing this ticket will take the room over capacity by " + deficit + ".  Are you sure you wish to issue these " + requested + " tickets?");
          }
        }
      }
    </script>
    </head>
  <body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
		<div class="container-fluid">
      <a class="navbar-brand" href="/ysticketing/">Ticketing</a>
      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
	<span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbarNav">
	<ul class="navbar-nav">
	  <li class="nav-item">
	    <a class="nav-link" href="/"><?php echo $sitename; ?></a>
	  </li>
	  <li class="nav-item">
	    <a class="nav-link active" href="/ysticketing/">Event Tickets</a>
	  </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
        <h1><?php if ($action == "extra") {
            echo "How Many Additional Tickets?";
        } else {
            echo "How Many Tickets?";
        } ?></h1>
        
      <form action="/cgi-bin/ysticketoverride.pl" method="POST">
        <div class="input-group input-group-lg">
            <span class="input-group-text" id="inputGroup-sizing-lg">Adults</span>
            <input type="number" name="adults" id="adults" class="form-control" value="<?php
            if ($action == "extra") {
                echo "0";
            } else {
                echo "1";
            } ?>">
        </div>
        <div class="input-group input-group-lg">
            <span class="input-group-text" id="inputGroup-sizing-lg">Children</span>
            <input type="number" id="children" name="children" class="form-control" value="1">
        </div>
        <input type="hidden" name="action" value="<?php echo $action; ?>">
        <?php if ($action == "extra") { ?>
            <input type="hidden" name="ticketid" value="<?php echo $ticketid; ?>">
        <?php } else { ?>
            <input type="hidden" name="eventid" value="<?php echo $eventid; ?>">
        <?php } ?>
        <button type="submit" class="btn btn-primary" onclick="return verify_count()">Submit</button>
        </form>
        </div>
        </main>
        </body>
        </html>