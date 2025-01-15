<?php require_once('Connections/ticketingdb.php');
require_once('common.php');

mysqli_select_db($ticketingdb, $database_ticketingdb);
$query_programlist = $ticketingdb->prepare("SELECT p.ProgramID, p.ProgramName, TIME_FORMAT(p.ProgramTime, '%l:%i %p') AS ProgramTime, p.ProgramDays, p.AgeRange, p.SecondTierMinutes, l.LocationDescription FROM TicketedPrograms p INNER JOIN TicketLocations l ON p.LocationID = l.LocationID WHERE p.Archived = 0 ORDER BY p.ProgramName");
$query_programlist->execute() or die(mysqli_error($ticketingdb));
$programlist = $query_programlist->get_result();
$programs = array();
while ($row = mysqli_fetch_assoc($programlist)) {
  $id = $row['ProgramID'];
  foreach ($row as $key => $value) {
    if ($key != 'ProgramID') {
      $programs[$id][$key] = $value;
    }
    $programs[$id]['EventCount'] = 0;
  }
}

$query_futureevents = $ticketingdb->prepare("SELECT e.ProgramID, COUNT(e.EventID) AS Events FROM TicketedEvents e INNER JOIN TicketedPrograms p ON e.ProgramID = p.ProgramID WHERE e.EventDate >= CURRENT_DATE() AND p.Archived = 0 GROUP BY e.ProgramID");
$query_futureevents->execute() or die(mysqli_error($ticketingdb));
$futureevents = $query_futureevents->get_result();
while ($row = mysqli_fetch_assoc($futureevents)) {
  $programs[$row['ProgramID']]['EventCount'] = $row['Events'];
}

?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Program Management</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
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
	    <a class="nav-link active" href="#">Program Management</a>
	  </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
        <h1>Program Management</h1>
        <p>Click on a program to modify, delete or archive that program and it's events.  Some quick guidelines:</p>
        <ul>
          <li>Changing the weekdays for a program will not affect existing scheduled events for that program.</li>
          <li>Changing the time of a program <strong>will</strong> change the time for any existing dates for that program.  If you need a need to add events for a program at a different time, create a new program with that time.</li>
          <li>Archiving a program will leave past and future events for a program untouched but will will remove the program from this page.  If you need to keep data for stats, do this.</li>
          <li>Rooms can be <a href="rooms.php">added or edited on this page</a>.</li>
          <li>Deleting a program will delete it and all past and future events associated with it.</li>
        </ul>
        <div class="mx-auto"><a class="btn btn-primary btn-lg" href="editprogram.php">Create a New Program</a></div>
<table class="table table-striped">
  <thead>
    <tr>
      <th>Program</th>
      <th>Time</th>
      <th>Scheduled Weekdays</th>
      <th>Age Range</th>
      <th>Room</th>
      <th>General Availability Minutes</th>
      <th>Scheduled Events</th>
    </tr>
  </thead>
  <tbody>
    <?php foreach ($programs as $id => $values) { ?>
      <tr>
        <td><a href="editprogram.php?programid=<?php echo $id; ?>"><?php echo $values['ProgramName'] ?></a></td>
        <td><?php echo $values['ProgramTime']; ?></td>
        <td>
        <?php
        $weekdays = explode (",", $values['ProgramDays']);
        if (in_array("Sunday", $weekdays)) {
          echo "<span class=\"badge rounded-pill text-bg-primary\">Su</span>";
        } else {
          echo "<span class=\"badge rounded-pill text-bg-secondary\">Su</span>";
        }
        if (in_array("Monday", $weekdays)) {
          echo "<span class=\"badge rounded-pill text-bg-primary\">Mo</span>";
        } else {
          echo "<span class=\"badge rounded-pill text-bg-secondary\">Mo</span>";
        }
        if (in_array("Tuesday", $weekdays)) {
          echo "<span class=\"badge rounded-pill text-bg-primary\">Tu</span>";
        } else {
          echo "<span class=\"badge rounded-pill text-bg-secondary\">Tu</span>";
        }
        if (in_array("Wednesday", $weekdays)) {
          echo "<span class=\"badge rounded-pill text-bg-primary\">We</span>";
        } else {
          echo "<span class=\"badge rounded-pill text-bg-secondary\">We</span>";
        }
        if (in_array("Thursday", $weekdays)) {
          echo "<span class=\"badge rounded-pill text-bg-primary\">Th</span>";
        } else {
          echo "<span class=\"badge rounded-pill text-bg-secondary\">Th</span>";
        }
        if (in_array("Friday", $weekdays)) {
          echo "<span class=\"badge rounded-pill text-bg-primary\">Fr</span>";
        } else {
          echo "<span class=\"badge rounded-pill text-bg-secondary\">Fr</span>";
        }
        if (in_array("Saturday", $weekdays)) {
          echo "<span class=\"badge rounded-pill text-bg-primary\">Sa</span>";
        } else {
          echo "<span class=\"badge rounded-pill text-bg-secondary\">Sa</span>";
        }
        ?></td>
        <td><?php echo $values['AgeRange']; ?></td>
        <td><?php echo $values['LocationDescription']; ?></td>
        <td><?php echo $values['SecondTierMinutes']; ?></td>
        <td><?php if ($values['EventCount'] > 0) { ?>
          <a href="eventlist.php?ProgramID=<?php echo $id; ?>&action=edit"><?php echo $values['EventCount']; ?></a>
          &nbsp;&nbsp;<a href="calendar.php?ProgramID=<?php echo $id; ?>" class="badge rounded-pill text-bg-primary" role="button">Schedule Events</a>
          <?php } else { 
          echo "0"; 
          echo "&nbsp;&nbsp;<a href=\"calendar.php?ProgramID=$id\" class=\"badge rounded-pill text-bg-primary\" role=\"button\">Schedule Events</a>";
        } ?>
        </td>
      </tr>
   <?php }
    ?>
    </tbody>
      </table>
<?php

?>
</div>
    </main>
    <script src="/bootstrap/js/jquery.min.js"></script>
<script src="/bootstrap/js/popper.js"></script>
<script src="/bootstrap/js/bootstrap.min.js"></script>
  </body>
</html>