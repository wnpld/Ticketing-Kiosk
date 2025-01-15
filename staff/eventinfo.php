<?php require_once('Connections/ticketingdb.php');
require_once('common.php');
if (isset($_REQUEST['eventid'])) {
    if (is_numeric($_REQUEST['eventid'])) {
        $eventid = $_REQUEST['eventid'];
        mysqli_select_db($ticketingdb, $database_ticketingdb);
        $formatted_today = date('Y-m-d');
        $query_eventdetails = sprintf("SELECT tp.ProgramName, tp.ProgramTime, (IFNULL(SUM(t.Adults),0) + IFNULL(SUM(t.Children),0)) AS TicketsIssued, tl.LocationDescription, tl.LocationCapacity, tl.GraceSpaces, te.TicketsHeld, (SELECT IFNULL((SUM(IFNULL(Adults,0)) + SUM(IFNULL(Children,0))),0) FROM Tickets WHERE (DistrictResidentID = 6 OR DistrictResidentID = 7) AND EventID = '$eventid') AS DistrictTickets FROM TicketedPrograms tp INNER JOIN TicketedEvents te ON tp.ProgramID = te.ProgramID LEFT JOIN Tickets t ON te.EventID = t.EventID INNER JOIN TicketLocations tl ON tp.LocationID = tl.LocationID WHERE te.EventDate = '$formatted_today' AND te.EventID = '$eventid'");
        $eventdetails = mysqli_query($ticketingdb, $query_eventdetails) or die(mysqli_error($ticketingdb));
        $totalRows_eventdetails = mysqli_num_rows($eventdetails);
        if ($totalRows_eventdetails == 1) {
            $eventinfo = mysqli_fetch_assoc($eventdetails);
            
            $query_ticketlist = sprintf("SELECT TicketID, Adults, Children, HEX(Identifier) AS Identifier, d.DistrictName AS Library FROM Tickets t INNER JOIN Districts d ON t.DistrictResidentID = d.DistrictID WHERE EventID = '$eventid'");
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
	<script src="/bootstrap/js/jquery.min.js"></script>
	<script src="/bootstrap/js/popper.js"></script>
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
			<?php
					#Calculate remaining district tickets since this can be a mess to do later
					$district_remaining = $eventinfo['TicketsHeld'] - $eventinfo['DistrictTickets'];
					if ($district_remaining < 0) {
						$district_remaining = 0;
					}
				?>
				<p><strong>Tickets Issued:</strong> <?php echo $eventinfo['TicketsIssued']; ?></p>
				<p><strong>Priority Tickets Remaining:</strong> <?php echo $district_remaining; ?></p>
 				<p><strong>General Tickets Remaining:</strong> <?php echo ($eventinfo['LocationCapacity'] - ($eventinfo['TicketsIssued'] + $district_remaining)); ?></p>
 				<p><strong>Total Tickets Remaining:</strong> <?php echo ($eventinfo['LocationCapacity'] - $eventinfo['TicketsIssued']); ?> (Grace Tickets: <?php echo $eventinfo['GraceSpaces']; ?>)</p>
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
					$id = substr($ticketinfo['Identifier'],-8,8);

					if (preg_match('/([0-9][0-9])\1{15}/', $ticketinfo['Identifier'], $matches)) {
						$id = "Staff " . $matches[1];
					}
				?>
				<tr id="<?php echo $ticketinfo['Identifier']; ?>"><td><?php echo $ticketinfo['Adults']; ?></td><td><?php echo $ticketinfo['Children']; ?></td><td><?php echo $id; ?> (<?php echo $ticketinfo['Library']; ?>)</td><td>
 					<button type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#cancelModal" data-bs-ticketinfo="<?php echo $ticketinfo['Adults']; ?>,<?php echo $ticketinfo['Children']; ?>,<?php echo $ticketinfo['TicketID']; ?>,<?php echo $eventid; ?>">Cancel Tickets</button>
 					<a href="issuetickets.php?ticketid=<?php echo $ticketinfo['TicketID']; ?>" class="btn btn-primary btn-sm">Add Tickets</a>
 					<a href="printtickets.php?ticketid=<?php echo $ticketinfo['TicketID']; ?>&reprint=true" target="_blank" class="btn btn-primary btn-sm">Reprint</a></td></tr>
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
 	 <div class="modal fade" id="cancelModal" tabindex="-1" role="dialog" aria-labelledby="cancelModalLabel" aria-hidden="true">
		<div class="modal-dialog" role="document">
			<div class="modal-content">
				<div class="modal-header">
					<h5 class="modal-title" id="cancelModalLabel">Cancel and Free Ticket(s)</h5>
					<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
						<span aria-hidden="true">&times;</span>
					</button>
				</div>
				<div class="modal-body">
					<p><em>Cancel tickets and make them available to others</em></p>
					<form action="/cgi-bin/ysticketaction.pl" method="GET">
						<div class="form-check">
							<input class="form-check-input" type="radio" id="cancelAll" name="Scope" value="all" checked>
							<label class="form-check-label" for="cancelAll">
								Cancel all tickets for this card
							</label>
						</div>
						<div class="form-check">
							<input class="form-check-input" type="radio" id="cancelOneAdult" name="Scope" value="adult">
							<label class="form-check-label" for="cancelOneAdult">
								Cancel one adult ticket
							</label>
						</div>
						<div class="form-check">
							<input class="form-check-input" type="radio" id="cancelOneChild" name="Scope" value="child">
							<label class="form-check-label" for="cancelOneChild">
								Cancel one child ticket
							</label>
						</div>
						<input type="hidden" id="TicketId" name="TicketId" value="">
						<input type="hidden" id="EventId" name="EventId" value="">
						<input type="hidden" id="ChildCount" name="ChildCount" value="0">
						<input type="hidden" id="AdultCount" name="AdultCount" value="0">
						<button type="submit" class="btn btn-primary">Cancel Ticket(s)</button>
					</form>
				</div>
				<div class="modal-footer">
					<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Abort</button>
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
	<script type="text/javascript">
		var cancelModal = document.getElementById('cancelModal');
		cancelModal.addEventListener('show.bs.modal', function (event) {
			var button = event.relatedTarget;
			var ticketinfo = button.getAttribute('data-bs-ticketinfo');
			const info = ticketinfo.split(",");
			//Element 0 is Adult Tickets
			if (info[0] <= 1) {
				cancelModal.querySelector('#cancelOneAdult').setAttribute('disabled', true);
			} else {
				cancelModal.querySelector('#AdultCount').value = info[0];
			}
			//Element 1 is Child Tickets
			if (info[1] <= 1) {
				cancelModal.querySelector('#cancelOneChild').setAttribute('disabled', true);
			} else {
				cancelModal.querySelector('#ChildCount').value = info[1]
			}
			cancelModal.querySelector('#TicketId').value = info[2];
			cancelModal.querySelector('#EventId').value = info[3];
		})
	</script>
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
