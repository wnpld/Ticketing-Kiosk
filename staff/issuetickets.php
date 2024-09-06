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
    $query_tickettotal = $ticketingdb->prepare("SELECT SUM(TicketsHeld) AS TicketsHeld, SUM(TicketsAvailable) AS TicketsAvailable FROM ((SELECT e.TicketsHeld, 0 AS TicketsAvailable FROM TicketedEvents e INNER JOIN Tickets t ON e.EventID = t.EventID WHERE t.TicketID = ?) UNION ALL (SELECT 0 AS TicketsHeld, ((l.LocationCapacity + l.GraceSpaces) - (SUM(IFNULL(t.Adults,0)) + SUM(IFNULL(t.Children,0)))) AS TicketsAvailable FROM TicketedEvents e INNER JOIN TicketedPrograms p ON e.ProgramID = p.ProgramID INNER JOIN TicketLocations l ON p.LocationID = l.LocationID LEFT JOIN Tickets t ON e.EventID = t.EventID WHERE e.EventID = (SELECT EventID FROM Tickets WHERE TicketID = ?) GROUP BY e.EventID)) t");
    $query_tickettotal->bind_param('ii', $ticketid, $ticketid);
    $query_tickettotal->execute() or die(mysqli_error($ticketingdb));
    $tickettotal = $query_tickettotal->get_result();
    $ticketstates = mysqli_fetch_assoc($tickettotal);
    $ticketsheld = $ticketstates['TicketsHeld'];
    $kiosktickets = $ticketstates['TicketsAvailable'] - $ticketsheld;
} else if (isset($_REQUEST['eventid'])) {
    #We're adding tickets from the staff interface
    if (!is_numeric($_REQUEST['eventid'])) {
        #Invalid ID
        header("Location: $protocol://$domain/$currentdir/\n\n");
        exit; 
    } else {
        $action = "new";
        $eventid = $_REQUEST['eventid'];
    }
    $query_tickettotal = $ticketingdb->prepare("SELECT SUM(TicketsHeld) AS TicketsHeld, SUM(TicketsAvailable) AS TicketsAvailable FROM ((SELECT e.TicketsHeld, 0 AS TicketsAvailable FROM TicketedEvents e WHERE e.EventID = ?) UNION ALL (SELECT 0 AS TicketsHeld, ((l.LocationCapacity + l.GraceSpaces) - (SUM(IFNULL(t.Adults,0)) + SUM(IFNULL(t.Children,0)))) AS TicketsAvailable FROM TicketedEvents e INNER JOIN TicketedPrograms p ON e.ProgramID = p.ProgramID INNER JOIN TicketLocations l ON p.LocationID = l.LocationID LEFT JOIN Tickets t ON e.EventID = t.EventID WHERE e.EventID = ? GROUP BY e.EventID)) t");
    $query_tickettotal->bind_param('ii', $eventid, $eventid);
    $query_tickettotal->execute() or die(mysqli_error($ticketingdb));
    $tickettotal = $query_tickettotal->get_result();
    $ticketstates = mysqli_fetch_assoc($tickettotal);
    $ticketsheld = $ticketstates['TicketsHeld'];
    $kiosktickets = $ticketstates['TicketsAvailable'] - $ticketsheld;
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
        var ticketsheld = <?php echo $ticketsheld; ?>;
        var kiosktickets = <?php echo $kiosktickets; ?>;
        var adults = Number(document.getElementById("adults").value);
        var children = Number(document.getElementById("children").value);
        var requested = adults+children;
        var heldleft = ticketsheld - requested;
        var kioskleft = kiosktickets;
        if (heldleft < 0) {
          kioskleft = kioskleft + heldleft;
        }
        if (heldleft >= 0) {
          return confirm("This order will use " + requested + " tickets of " + ticketsheld + " held tickets leaving " + heldleft + " held tickets and " + kioskleft + " kiosk tickets. Please confirm.");
        } else if ((heldleft < 0) && (kioskleft >= 0)) {
          return confirm("This order for " + requested + " tickets will use " + ticketsheld + " held tickets as well as " + Math.abs(heldleft) + " kiosk tickets, leaving " + kioskleft + " kiosk tickets.  Please confirm.");
        } else if (kioskleft < 0) {
          return confirm("This order for " + requested + " tickets will use " + ticketsheld + " held tickets and all " + kiosktickets + " remaining kiosk tickets.  It will exceed the stated room capacity by " + Math.abs(kioskleft) + ".  Please confirm.");
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