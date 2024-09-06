<?php require_once('Connections/ticketingdb.php'); 
require_once('common.php');
mysqli_select_db($ticketingdb, $database_ticketingdb);
$formatted_today = date('Y-m-d');
$query_todaysevents = sprintf("SELECT tp.ProgramName, tp.ProgramTime, (IFNULL(SUM(t.Adults),0) + IFNULL(SUM(t.Children),0)) AS TicketsIssued, tl.LocationDescription, tl.LocationCapacity, tl.GraceSpaces, te.EventID, te.TicketsHeld FROM TicketedPrograms tp INNER JOIN TicketedEvents te ON tp.ProgramID = te.ProgramID LEFT JOIN Tickets t ON te.EventID = t.EventID INNER JOIN TicketLocations tl ON tp.LocationID = tl.LocationID WHERE te.EventDate = '$formatted_today' GROUP BY tp.ProgramTime ORDER BY tp.ProgramTime");
$todaysevents = mysqli_query($ticketingdb, $query_todaysevents) or die(mysqli_error($ticketingdb));
$totalRows_todaysevents = mysqli_num_rows($todaysevents);
?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Ticketing Management</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
  </head>
  <body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
		<div class="container-fluid">
      <a class="navbar-brand" href="#">Ticketing</a>
      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
	<span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbarNav">
	<ul class="navbar-nav">
	  <li class="nav-item">
	    <a class="nav-link" href="/"><?php echo $sitename; ?></a>
	  </li>
	  <li class="nav-item">
	    <a class="nav-link active" href="#">Ticketing Management</a>
	  </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
	  <div class="pb-5 mb-4 bg-light rounded-3">
				<div class="container-fluid py-4">
	  				<h1 class="display-5 fw-bold">Ticketing Mangement</h1>
</div>
	</div>
	<div class="row">
	    <div class="card" style="width: 50rem;">
	      <div class="card-body">
		<h2 class="card-title">Today's Events</h2>
		<div class="card-text">
		<?php
		if ($totalRows_todaysevents > 0) { ?>
			<p>For any events which are upcoming or ongoing, you can click on the event to get ticket information make changes.</p>
		<?php
			while ($event = mysqli_fetch_assoc($todaysevents)) { 
				$capacity = $event['LocationCapacity'];
		   		$grace = $event['GraceSpaces'];
		   		$tickets = $event['TicketsIssued'];
		   		$held = $event['TicketsHeld'];
		   		$program = $event['ProgramName'];
		   		$location = $event['LocationDescription'];
		   		$eventtime = strtotime($event['ProgramTime']);
		   		$eventid = $event['EventID'];
		   		$time = date('g:i a', $eventtime);

		   		#This assumes all events last about 30 minutes.  This is probably
		   		#not true, but it's good enough
		   		$eventpasttime = $eventtime + 1800;

		   		$eventline = "<h4>";
		   		if ($eventtime > time()) {
			  		$eventline .= "<a href=\"eventinfo.php?eventid=" . $eventid . "\">" . $program . "</a>";
		      		#Event hasn't happened yet.  Calculate Ticket status
		      		$ticketsremaining = ($capacity + $grace) - $tickets;
		      		if ($ticketsremaining < 3) {
		      	 		$eventline .= " <span class=\"badge text-bg-danger\">Event Full</span>";
			 		} else if ($ticketsremaining < 5) {
			   			$eventline .= " <span class=\"badge text-bg-warning\">Event Almost Full (" . $ticketsremaining . " spots left)</span>";
			 		} else {
			   			$ticketsremaining = $ticketsremaining - $grace;
			   			$eventline .= " <span class=\"badge text-bg-success\">Tickets Remaining: " . $ticketsremaining . "</span>";
			 		}
			 		if ($held > 0) {
			 			$eventline .= " <span class=\"badge text-bg-warning\">Tickets Held: " . $held . "</span>";
			 		}
		    	} else if ($eventtime > $eventpasttime) {
			  		$eventline .= "<a href=\"eventinfo.php?eventid=" . $eventid . ">" . $program . "</a>";
		      		#Event has started but it's been less than a half hour
		      		#Calculate ticket status but indicate that event is ongoing
		      		$ticketsremaining = ($capacity + $grace) - $tickets;
		      		if ($ticketsremaining < 3) {
		      	 		$eventline .= " <span class=\"badge text-bg-danger\">Event Started at Capacity</span>";
		      		} else if ($ticketsremaining < 5) {
		      			$eventline .= " <span class=\"badge text-bg-warning\">Event Started (only " . $ticketsremaining . " spots left)</span>";
		      		} else {
						$ticketsremaining = $ticketsremaining - $grace;
						$eventline .= " <span class=\"badge text-bg-success\">Event Started (" . $ticketsremaining . " spots left)</span>";
		      		}
		    	} else {
					#Event is over
					$eventline .= $program . " <span class=\"badge text-bg-secondary\">Event Concluded</span>";
		    	}
				$eventline .= "</h4>";
				echo $eventline;
			}
		} else { ?>
		       <div class="alert alert-primary">No events scheduled for today.</div>
  <?php } ?>
		  </div>
		</div>
	      </div>
	    <div class="row">
	      <div class="card" style="width: 50rem;">
		<div class="card-body">
		<h2 class="card-title">Manage Programs</h2>
		  <div class="card-text">
			<p><span class="badge text-bg-info">Step 1</span> Use this page to add or delete general program information.  This includes program names, their weekly schedules, the rooms they are scheduled for or their capacity.</p>
			<p><a href="programs.php" class="btn btn-primary" role="button">Manage Programs</a></p>
		</div>
		</div>
		</div>
	    <div class="row">
	      <div class="card" style="width: 50rem;">
		<div class="card-body">
		<h2 class="card-title">Manage Calendar</h2>
		  <div class="card-text">
			<p><span class="badge text-bg-info">Step 2</span> Use this page to schedule or cancel events in the event calendar.  Each scheduled event is associated with an existing program.</p>
			<p><a href="calendar.php" class="btn btn-primary" role="button">Manage Calendar</a></p>
				</div>
	      	</div>
	  </div>
	</div>
    </main>
    <script src="/bootstrap/js/jquery.min.js"></script>
    <script src="/bootstrap/js/popper.js"></script>
    <script src="/bootstrap/js/bootstrap.min.js"></script>
  </body>
</html>
