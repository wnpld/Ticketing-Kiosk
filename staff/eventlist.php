<?php require_once('Connections/ticketingdb.php');
require_once('common.php');

mysqli_select_db($ticketingdb, $database_ticketingdb);

if (isset($_REQUEST['ProgramID'])) {
  if (is_numeric($_REQUEST['ProgramID'])) {
    $programid = $_REQUEST['ProgramID'];
  } else {
    print "Location: $protocol://$domain/$currentdir/calendar.php\n\n";
  }
} else {
  print "Location: $protocol://$domain/$currentdir/calendar.php\n\n";
}

#Get general program information
$query_programdata = $ticketingdb->prepare("SELECT ProgramName, ProgramTime, ProgramDays, AgeRange FROM TicketedPrograms WHERE ProgramID = ?");
$query_programdata->bind_param('i', $programid) or die(mysqli_error($ticketingdb));
$query_programdata->execute() or die(mysqli_error($ticketingdb));
$programdata = $query_programdata->get_result();
$programinfo = mysqli_fetch_assoc($programdata);

$programname = $programinfo['ProgramName'];
$programdays = $programinfo['ProgramDays'];
$time = date('g:i a', strtotime($programinfo['ProgramTime']));
if (preg_match('/(\d+-\d+)m/', $programinfo['AgeRange'], $matches)) {
  $agerange = $matches[1] . " months";
} else if (preg_match('/(\d+-\d+)y/', $programinfo['AgeRange'], $matches)) {
  $agerange = $matches[1] . " years";
}

#start date defaults to today if not provided
if (isset($_REQUEST['startDate'])) {
  if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $_REQUEST['startDate'])) {
    $startdate = $_REQUEST['startDate'];
  } else {
    print "Location: $protocol://$domain/$currentdir/calendar.php\n\n";
  }
} else {
  $startdate = date('Y-m-d');
}

#end date is only needed for creating events, so it's not strictly required at this point
if (isset($_REQUEST['endDate'])) {
  if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $_REQUEST['endDate'])) {
    $enddate = $_REQUEST['endDate'];
  } else {
    print "Location: $protocol://$domain/$currentdur/calendar.php\n\n";
  }
}

$action = $_REQUEST['action'];
if ($action == "edit") {
  #Get a list of existing events with IDs
  $query_eventlist = $ticketingdb->prepare("SELECT EventID, EventDate FROM TicketedEvents WHERE ProgramID = ? AND EventDate >= ? ORDER BY EventDate ASC");
  $query_eventlist->bind_param('is', $programid, $startdate) or die(mysqli_error($ticketingdb));
  $query_eventlist->execute() or die(mysqli_error($ticketingdb));
  $eventlist = $query_eventlist->get_result();
  $events = array();
  while ($row = mysqli_fetch_assoc($eventlist)) {
    $events[$row['EventID']] = date('D, F j, Y', strtotime($row['EventDate']));
  }

} else if ($action == "create") {
  #Only need to know if there is event overlap with the submitted dates
  $query_eventdates = $ticketingdb->prepare("SELECT EventDate FROM TicketedEvents WHERE ProgramID = ? AND EventDate BETWEEN ? AND ? ORDER BY EventDate ASC");
  $plain_eventdates = "SELECT EventDate FROM TicketedEvents WHERE ProgramID = $programid AND EventDate BETWEEN '$startdate' AND '$enddate' ORDER BY EventDate ASC";
  $query_eventdates->bind_param('iss', $programid, $startdate, $enddate) or die(mysqli_error($ticketingdb));
  $query_eventdates->execute() or die(mysqli_error($ticketingdb));
  $eventdates = $query_eventdates->get_result();
  $oldeventdates = array();
  $oldeventsplain = array();
  while ($row = mysqli_fetch_assoc($eventdates)) {
    array_push($oldeventdates, $row['EventDate']);
  }
} else {
  #Don't know what happened to get someone here, but they shouldn't be
  print "Location: $protocol://$domain/$currentdir/calendar.php\n\n";
}

?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Event Listing</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
    <script src="/bootstrap/js/jquery.min.js"></script>
    <script>
      function toggleDelete(id) {
        badge = "#badge-check-" + id;
        if ($(badge).text() == "Keeping") {
          $(badge).text("Removing");
          $(badge).removeClass("text-bg-warning")
          $(badge).addClass("text-bg-danger");
        } else {
          $(badge).text("Keeping");
          $(badge).removeClass("text-bg-danger");
          $(badge).addClass("text-bg-warning");
        }
      }

      function toggleSkip(counter) {
        badge = "#badge-check-" + counter;
        console.log(badge);
        if ($(badge).text() == "Keeping") {
          $(badge).text("Skipping");
          $(badge).removeClass("text-bg-warning");
          $(badge).addClass("text-bg-danger");
        } else {
          $(badge).text("Keeping");
          $(badge).removeClass("text-bg-danger");
          $(badge).addClass("text-bg-warning");
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
	    <a class="nav-link" href="calendar.php">Calendar Management</a>
	  </li>
    <li class="nav-item">
      <a class="nav-link active" href="#">Event Listing</a>
    </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
        <h1>Events for <?php echo $programname; ?></h1>
        <h2><?php echo $programdays . " - " . $time . " - " . $agerange; ?></h2>
        <?php if ($action == "edit") { ?>
          <h3>Edit Current Schedule</h3>
          <form action="/cgi-bin/ticketdropadd.pl" method="POST">
            <div class="row">
            <?php
              $counter = 0;
              foreach ($events AS $id => $date) { 
                if ($counter != 0) {
                   if ($counter % 3 == 0) { ?>
              </div>
              </div>
              <div class="row">
                <?php } else { ?>
                </div>
              <?php }
              } ?>
              <div class="col-3"> 
              <div class="input-group mb-3">
                <input type="checkbox" class="btn-check" id="btn-check-<?php echo $id; ?>" name="EventID" value="<?php echo $id; ?>" autocomplete="off">
                <label class="btn btn-success" for="btn-check-<?php echo $id; ?>" onclick="toggleDelete(<?php echo $id; ?>)"><?php echo $date; ?><span style="font-weight: bold; font-size: .75em; padding-top: .35em; padding-bottom: .35em; padding-left: .65em; padding-right: .65em;" class="position-absolute top-0 start-100 translate-middle rounded-pill text-bg-warning" id="badge-check-<?php echo $id; ?>">Keeping</span></label>
              </div>
              <?php 
              $counter++;
              }
            ?>
            </div>
                </div>
            <input type="submit" class="btn btn-primary btn-large" value="Delete Selected Events">
        <?php } else { ?>
          <h3>Add New Events</h3>
          <form action="/cgi-bin/ticketdropadd.pl" method="POST">
          <?php if (count($oldeventdates) > 0) { ?>
          <p>There was some overlap between already scheduled events and the date range you selected.  Any overlapping dates have been dropped from this list.</p>
          <?php }
          $starttimestamp = strtotime($startdate)+7200; //Some time is added here to make sure we don't have any problems with DST
          $endtimestamp = strtotime($enddate)+7200;
          $proposed = array();
          for ($x = $starttimestamp; $x <= $endtimestamp; $x += 86400) {
            if (str_contains($programdays, date('l', $x))) {
              if (in_array(date('Y-m-d', $x), $oldeventdates)) {
                continue;
              } else {
                $shortdate = date('Y-m-d', $x);
                $proposed[$shortdate] = date('D, F j, Y', $x);
              }
            }
          }
          $counter = 0;
          ?>
          <div class="row">
            <?php
          foreach ($proposed AS $date => $formatted) { 
            if ($counter != 0) {
              if ($counter % 3 == 0) { ?>
                </div>
              </div>
              <div class="row">
              <?php } else { ?>
              </div>
              <?php }  
            } ?>
          <div class="col-3">
            <div class="input-group mb-3">
            <input type="checkbox" class="btn-check" id="btn-check-<?php echo $counter; ?>" autocomplete="off" name="EventDate" value="<?php echo $date; ?>" checked>
            <label class="btn btn-success" for="btn-check-<?php echo $counter; ?>" onclick="toggleSkip(<?php echo $counter; ?>)"><?php echo $formatted; ?><span style="font-weight: bold; font-size: .75em; padding-top: .35em; padding-bottom: .35em; padding-left: .65em; padding-right: .65em;" class="position-absolute top-0 start-100 translate-middle rounded-pill text-bg-warning" id="badge-check-<?php echo $counter; ?>">Keeping</span></label>
          </div>            
          <?php 
            $counter++;
          } ?>
          </div>
        </div>
                  <input type="hidden" name="ProgramID" value="<?php echo $programid; ?>">
                  <input type="submit" class="btn btn-primary btn-large" value="Add These Event Dates">
      <?php  } ?>
      </form>
</div>
</main>
</html>