<?php require_once('Connections/ticketingdb.php');
require_once('common.php');
if (isset($_REQUEST['eventid'])) {
    if (is_numeric($_REQUEST['eventid'])) {
        $eventid = $_REQUEST['eventid'];
        mysqli_select_db($ticketingdb, $database_ticketingdb);
        $formatted_today = date('Y-m-d');
        $query_eventdetails = sprintf("SELECT tp.ProgramName, tp.ProgramTime, (IFNULL(SUM(t.Adults),0) + IFNULL(SUM(t.Children),0)) AS TicketsIssued, tl.LocationDescription, tl.LocationCapacity, tl.GraceSpaces, te.TicketsHeld FROM TicketedPrograms tp INNER JOIN TicketedEvents te ON tp.ProgramID = te.ProgramID LEFT JOIN Tickets t ON te.EventID = t.EventID INNER JOIN TicketLocations tl ON tp.LocationID = tl.LocationID WHERE te.EventDate = '$formatted_today' AND te.EventID = '$eventid'");
        $eventdetails = mysqli_query($ticketingdb, $query_eventdetails) or die(mysqli_error($ticketingdb));
        $totalRows_eventdetails = mysqli_num_rows($eventdetails);
        if ($totalRows_eventdetails == 1) {
            $eventinfo = mysqli_fetch_assoc($eventdetails);
            
            $query_ticketlist = sprintf("SELECT TicketID, Adults, Children, HEX(Identifier) AS Identifier FROM Tickets WHERE EventID = '$eventid'");
            $ticketlist = mysqli_query($ticketingdb, $query_ticketlist) or die(mysqli_error($ticketingdb));
            $totalRows_ticketlist = mysqli_num_rows($ticketlist);
            
            $time = date('g:i a', strtotime($eventinfo['ProgramTime']));
?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Event Tickets</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
	<script type="text/javascript">
		async function highlightTickets() {
			var id = document.getElementById('identifier').value;
			var url = "<?php echo $protocol; ?>://<?php echo $domain; ?>/<?php echo $cgi; ?>/bcencode.pl?bc=" + id;
			console.log(url);
			try {
				let response = await fetch(url);
				let hash = await response.text();
				if (document.getElementById(hash)) {
					document.getElementById(hash).classList.add("table-danger");
				} else {
					window.alert("Barcode/phone number not found.");
				}

			} catch (error) {
				console.error(error.message);
			}
		}

		function resetTable() {
			var elems = document.querySelectorAll(".table-danger");
			[].forEach.call(elems, function(el) {
				el.classList.remove("table-danger");
			});
		}

		function cancelTickets(url) {
			var confirmed = confirm("Do you really want to cancel these tickets?");
			if (confirmed == true) {
				window.location.replace(url);
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
	    <a class="nav-link active" href="#">Event Tickets</a>
	  </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
	  <div class="pb-5 mb-4 bg-light rounded-3">
				<div class="container-fluid py-4">
	  				<h1><?php echo $eventinfo['ProgramName']; ?></h1>
                    <h2><?php echo $time . " - " . $eventinfo['LocationDescription']; ?></h2>
				</div>
	</div>
	<div class="card">
		<div class="row">
			<div class="col-4">
				<p><strong>Tickets Issued:</strong> <?php echo $eventinfo['TicketsIssued']; ?></p>
				<p><strong>Tickets Held:</strong> <?php echo $eventinfo['TicketsHeld']; ?></p>
				<p><strong>Kiosk Tickets Remaining:</strong> <?php echo ($eventinfo['LocationCapacity'] + $eventinfo['GraceSpaces']) - ($eventinfo['TicketsIssued'] + $eventinfo['TicketsHeld']); ?></p>
				<p><strong>Total Tickets Remaining:</strong> <?php echo ($eventinfo['LocationCapacity'] + $eventinfo['GraceSpaces']) - $eventinfo['TicketsIssued']; ?></p>
			</div>
			<div class="col-2 mx-auto">
<?php
	#Calculate event image
	$emojiid;
	$emojiseed = $_REQUEST['eventid'];
	$emojiseed += 100;
	$emojiseed = $emojiseed % 33;
	$emojiseed++;
	if ($emojiseed < 10) {
		$emojiid = "emoji0" . $emojiseed . ".png";
	} else {
		$emojiid = "emoji" . $emojiseed . ".png";
	}
?>
				<div><img alt="This event's image." src="images/<?php echo $emojiid; ?>"></div>
				<p><em>All tickets for this event use this image.</em></p>
			</div>
			<div class="col-5">
				<p><strong>Check card/phone number:</strong></p>
				<div><input type="text" id="identifier"><button id="idsend" class="btn btn-primary" onclick="highlightTickets()">Check</button></div>
				<div><button type="button" class="btn btn-secondary" onclick="resetTable()">Reset</button></div>
				<hr>
				<p><strong><a href="issuetickets.php?eventid=<?php echo $_REQUEST['eventid']; ?>">Issue tickets for this event.</a></strong></p>
			</div>
		</div>
	</div>
	<div class="row">
	    <div class="card">
	      <div class="card-body">
	      <?php
  	      	if ($totalRows_ticketlist > 0) {
  	      	?>
	      <table class="table table-striped">
	      	<thead>
	  
	      		<tr>
	      			<th>Adults</th><th>Children</th><th>Identifier</th><th>Actions</th>
	      		</tr>
	      	</thead>
	      	<tbody>
	      	<?php
		      	while($ticketinfo = mysqli_fetch_assoc($ticketlist)) { 
					$cancelurl = $protocol . "://" . $domain . "/" . $cgi . "/ysticketaction.pl?id=" . $ticketinfo['TicketID'] . "&action=free&eventid=" . $eventid;
					$cancelholdurl = $protocol . "://" . $domain . "/" . $cgi . "/ysticketaction.pl?id=" . $ticketinfo['TicketID'] . "&action=hold&eventid=" . $eventid;
					$id = substr($ticketinfo['Identifier'],-8,8);

					if (preg_match('/([0-9][0-9])\1{15}/', $ticketinfo['Identifier'], $matches)) {
						$id = "Staff " . $matches[1];
					}
				?>
	      		<tr id="<?php echo $ticketinfo['Identifier']; ?>"><td><?php echo $ticketinfo['Adults']; ?></td><td><?php echo $ticketinfo['Children']; ?></td><td><?php echo $id; ?></td><td><a href="#" onclick='cancelTickets("<?php echo $cancelurl; ?>")'>Cancel and Free</a> / <a href="#" onclick='cancelTickets("<?php echo $cancelholdurl; ?>")'>Cancel and Hold</a> / <a href="issuetickets.php?ticketid=<?php echo $ticketinfo['TicketID']; ?>">Add Tickets</a> / <a href="printtickets.php?ticketid=<?php echo $ticketinfo['TicketID']; ?>&reprint=true" target="_blank">Reprint</a></td></tr>
	      	<?php }

	      	?>
	      	</tbody>
	      </table>
	      <?php } else {
	      		echo "No tickets requested yet.";
	      	} ?>
	     </div>
	    </div>
	   </div>
	  </div>
	 </div>
	 <script type="text/javascript">
		//Input field
		var input = document.getElementById("identifier");

		//Hit button when you hit enter in the field
		input.addEventListener("keypress", function(event) {
			if (event.key === "Enter") {
				event.preventDefault();
				document.getElementById("idsend").click();
			}
		});


	</script>
	<script src="/bootstrap/js/jquery.min.js"></script>
<script src="/bootstrap/js/popper.js"></script>
<script src="/bootstrap/js/bootstrap.min.js"></script>
	</body>
</html>

<?php
        } else {
            #Invalid event id or event id isn't for today
            header('Location: ' . $protocol . '://' . $domain . '/ysticketing/');
        }
    } else {
        #Event id isn't numeric
        header('Location: ' . $protocol . '://' . $domain . '/ysticketing/');
        exit;
    }
} else {
    #No event id provided
    header('Location: ' . $protocol . '://' . $domain . '/ysticketing/');
} ?>
