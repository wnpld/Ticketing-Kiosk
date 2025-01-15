<?php require_once 'Connections/ticketingdb.php';
require_once 'common.php';

mysqli_select_db($ticketingdb, $database_ticketingdb);
$query_programinfo = $ticketingdb->prepare("SELECT ProgramID, ProgramName, ProgramTime, ProgramDays FROM TicketedPrograms WHERE Archived = 0 ORDER BY ProgramName ASC, ProgramTime ASC, ProgramDays ASC");
$query_programinfo->execute() or die(mysqli_error($ticketingdb));
$programinfo = $query_programinfo->get_result();
$programdata = array();
$daylist = array("Sunday"=>array("Su",0),"Monday"=>array("M",1),"Tuesday"=>array("Tu",2),"Wednesday"=>array("W",3),"Thursday"=>array("Th",4),"Friday"=>array("F",5),"Saturday"=>array("Sa",6));
while ($row = mysqli_fetch_assoc($programinfo)) {
  $shortdays = "";
  $notdays = "";
  $name = $row['ProgramName'];
  $time = date("g:i a", strtotime($row['ProgramTime']));
  $days = $row['ProgramDays'];
  foreach ($daylist AS $day => $abbrev) {
    if (str_contains($days, $day)) {
      $shortdays .= $daylist[$day][0];
    } else {
      $notdays .= $daylist[$day][1];
    }
  }
  $programdata[$row['ProgramID']]['Name'] = $name;
  $programdata[$row['ProgramID']]['Time'] = $time;
  $programdata[$row['ProgramID']]['Days'] = $shortdays;
  $programdata[$row['ProgramID']]['NotDays'] = $notdays;
}

$startdatestring = date("Y-m-d");
$enddatestring = date("Y-m-d");

if (isset($_REQUEST['ProgramID'])) {
  $requestedid = $_REQUEST['ProgramID'];
} else {
  $requestedid = 0;
}

?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Event Tickets</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
    <script src="/bootstrap/js/jquery.min.js"></script>
    <link id="bsdp-css" href="/datepicker/bootstrap-datepicker3.min.css" rel="stylesheet">
    <script src="/datepicker/bootstrap-datepicker.min.js"></script>
    <script>
      function calendarAdjust() {
        var dayrules = {};
        <?php foreach ($programdata AS $id => $values) { ?>
        dayrules["<?php echo $id; ?>"] = '<?php echo $values['NotDays']; ?>';
        <?php } ?>
        var id = $('#genProgram').val();
        $('#endRules').datepicker('setDaysOfWeekDisabled', dayrules[id]);
        $('#startRules').datepicker('setDaysOfWeekDisabled', dayrules[id]);
      }
    </script>
    <script>
      function adjustEndDate() {
        var startDateString = $('#startDate').val();
        var endDateString = $('#endDate').val();
        var startDate = new Date(startDateString);
        var endDate = new Date(endDateString);
        if (endDate < startDate) {
          $('#endRules').datepicker('setStartDate', startDateString);
          $('#endDate').val(startDateString);
        }
      }
    </script>
    </head>
  <body onload="calendarAdjust();">
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
	    <a class="nav-link active" href="#">Calendar Management</a>
	  </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
        <h1>Calendar Management</h1>
        <form action="eventlist.php" method="POST">
        <div class="row">
          <div class="col-8">
            <h2>Create Program Events</h2>
            <p>Use this form to generate events on all weekdays the event is scheduled for during a specified period.</p>
</div>
</div>
<div class="row">
  <div class="col-8">
    <div class="input-group mb-3">
      <select class="form-select" id="genProgram" name="ProgramID" onchange="calendarAdjust()">
      <?php
      foreach ($programdata AS $id => $values)  { ?>
      <option value="<?php echo $id; ?>" <?php if ($id == $requestedid) { echo "SELECTED";} ?>><?php echo $values['Name'] . " (" . $values['Days'] . " at " . $values['Time'] . ")"; ?></option>
      <?php } ?>
      </select>
    </div>
  </div>
  <div class="row">
    <div class="col-4">
      <label for="startDate" class="form-label">Beginning of Event Run:</label>
      <div id="startRules" class="input-group date" data-provide="datepicker" data-date-start-date="<?php echo $startdatestring; ?>" data-date-days-of-week-disabled="0,6">
        <input id="startDate" name="startDate" class="form-control" type="text"  value="<?php echo $startdatestring; ?>" onchange="adjustEndDate()">
        <div class="input-group-addon">
          <span class="glyphicon glyphicon-th">
          </span>
        </div>
      </div>
    </div>
    <div class="col-4">
      <label for="endDate" class="form-label">End of Event Run:</label>
      <div id="endRules" class="input-group date" data-provide="datepicker" data-date-start-date="<?php echo $enddatestring; ?>" data-date-days-of-week-disabled="0,6">
        <input id="endDate" name="endDate" class="form-control" type="text"  value="<?php echo $enddatestring; ?>">
        <div class="input-group-addon">
          <span class="glyphicon glyphicon-th">
          </span>
        </div>
      </div>
    </div>
  </div>
  <div class="row p-2">
    <div class="col-8 mx-auto">
      <input type="hidden" name="action" value="create">
      <input type="submit" class="btn btn-primary btn-lg" value="Generate Events">
    </div>
  </div>
</form>
<form action="eventlist.php" method="POST">
        <div class="row">
          <div class="col-8">
            <h2>View/Edit Program Schedule</h2>
            <p>Use this form to list scheduled events and to remove events from the schedule for a specific program.</p>
            <select class="form-select" id="editProgram" name="ProgramID">
            <?php
      foreach ($programdata AS $id => $values)  { ?>
      <option value="<?php echo $id; ?>" <?php if ($id == $requestedid) { echo "SELECTED"; } ?>><?php echo $values['Name'] . " (" . $values['Days'] . " at " . $values['Time'] . ")"; ?></option>
      <?php } ?>
      </select>
      <input type="hidden" name="action" value="edit">

          </div>
        </div>
        <div class="row p-2">
          <div class="col-8 mx-auto">
        <input type="submit" class="btn btn-primary btn-lg" value="Edit Events">
      </div>
      </div>
      </form>
        </div>

        <script type="text/javascript">
        $('.date').datepicker({
          format: "yyyy-mm-dd",
        });
      </script>
      <script src="../bootstrap/js/bootstrap.bundle.min.js"></script>
    </main>
  </body>
</html>