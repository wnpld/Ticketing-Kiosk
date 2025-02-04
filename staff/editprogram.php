<?php require_once('Connections/ticketingdb.php');
require_once('common.php');

mysqli_select_db($ticketingdb, $database_ticketingdb);

#Default is to create a new program.  Go to the default if there's 
#anything fishy about the submitted program id
$programid = "new";
if (isset($_REQUEST['programid'])) {
  if (is_numeric($_REQUEST['programid'])) {
    $programid = $_REQUEST['programid'];
  }
}

if ($programid != "new") {
  $query_programdata = $ticketingdb->prepare("SELECT ProgramName, ProgramTime, ProgramDays, AgeRange, SecondTierMinutes, LocationID, DefaultHeld, Capacity, Grace, ChildOnly FROM TicketedPrograms WHERE ProgramID = ?");
  $query_programdata->bind_param('i',$programid);
  $query_programdata->execute() or die(mysqli_error($ticketingdb));
  $programdata = $query_programdata->get_result();
  $programinfo = mysqli_fetch_assoc($programdata);

  $query_eventcount = $ticketingdb->prepare("SELECT COUNT(EventID) AS Total FROM TicketedEvents WHERE ProgramID = ?");
  $query_eventcount->bind_param('i', $programid);
  $query_eventcount->execute() or die(mysqli_error($ticketingdb));
  $eventcount = $query_eventcount->get_result();
  $eventinfo = mysqli_fetch_assoc($eventcount);
}

$locationinfo = array();
$query_locationdata = $ticketingdb->prepare("SELECT LocationID, LocationDescription, LocationCapacity, GraceSpaces, DefaultHeld from TicketLocations ORDER BY LocationDescription ASC");
$query_locationdata->execute() or die(mysqli_error($ticketingdb));
$locationdata = $query_locationdata->get_result();
while ($row = mysqli_fetch_assoc($locationdata)) {
  $locationinfo[$row['LocationID']]['Description'] = $row['LocationDescription'];
  $locationinfo[$row['LocationID']]['Capacity'] = $row['LocationCapacity'];
  $locationinfo[$row['LocationID']]['DefaultHeld'] = $row['DefaultHeld'];
  $locationinfo[$row['LocationID']]['Grace'] = $row['GraceSpaces'];
}

$days = explode (",", $programinfo['ProgramDays']);

?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Add/Edit Program</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
    <script>
      function checkampm() {
        hours = document.getElementById("ProgramHours").value;
        if (hours >= 12) {
          document.getElementById("ampm").innerHTML="pm";
        } else {
          document.getElementById("ampm").innerHTML="am";
        }
      }

      function agechange(type) {
        lowage = Number(document.getElementById("lowage").value);
        highage = Number(document.getElementById("highage").value);
        if (type == "low") {
          if (highage < lowage) {
            highage = lowage + 1;
            document.getElementById("highage").value=highage;
          }
        } else {
          if (lowage > highage) {
            lowage = highage - 1;
            document.getElementById("lowage").value=lowage;
          }
        }
      }

      function validate() {
        //Only really two things to check:
        // - The program has a name
        // - At least one weekday is selected
        var weekday = false;
        var name = false;

        //Check weekdays first
        if ((document.getElementById("Sunday").checked == 1) || (document.getElementById("Monday").checked == 1) || (document.getElementById("Tuesday").checked == 1) || (document.getElementById("Wednesday").checked == 1) || (document.getElementById("Thursday").checked == 1) || (document.getElementById("Friday").checked == 1) || (document.getElementById("Saturday").checked == 1)) {
          weekday = true;
        } 

        //Check program name
        var progname = document.getElementById("progname").value;
        if (progname.length > 5) {
          name = true;
        }

        if (name && weekday) {
          return true;
        } else if ((name == false) && (weekday == false)) {
          alert("Please provide a name for your program (more than 5 characters) and select at least one weekday.");
          return false;
        } else if (name == false) {
          alert("Please provide a name for your program (more than 5 characters).");
          return false;
        } else {
          alert("Please select at least one weekday.");
          return false;
        }
      }

      function updateCapacityGrace() {
        var rooms = {};
        <?php foreach ($locationinfo AS $id => $values) {
          echo "rooms[" . $id . "] = {};";
          echo "rooms[" . $id . "].capacity = " . $values['Capacity'] . ";";
          echo "rooms[" . $id . "].grace = " . $values['Grace'] . ";";
          echo "rooms[" . $id . "].held = " . $values['DefaultHeld'] . ";";
        } ?>
        var id = document.getElementById("LocationID").value;
        if (rooms[id].capacity != null) {
          document.getElementById("Capacity").max=rooms[id].capacity;
          document.getElementById("Capacity").value=rooms[id].capacity;
         }
        if (rooms[id].grace != null) {
          document.getElementById("Grace").max=rooms[id].grace;
          document.getElementById("Grace").value=rooms[id].grace;
        }
        if (rooms[id].held != null) {
          document.getElementById("DefaultHeld").value=rooms[id].held;
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
	    <a class="nav-link active" href="#">Edit Program</a>
	  </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
        <div class="row">
          <div class="col-7 mx-auto">
        <h1><?php 
        echo ($programid == "new" ? "Add" : "Edit") ?> Program</h1>
        <form action="/cgi-bin/addystickprog.pl" method="POST">
          <div class="input-group mb-3">
            <span class="input-group-text" id="ProgramName">Program Name</span>
            <input type="text" class="form-control" id="progname" aria-label="Program Name" name="ProgramName" aria-describedby="ProgramName" <?php if ($programid != "new") echo 'value="' . $programinfo['ProgramName'] . '" '?>>
          </div>
          <div class="input-group mb-3">
            <?php
            if ($programid != "new") {
              $fulltime = explode (":", $programinfo['ProgramTime']);
              $hours = $fulltime[0];
              $minutes = $fulltime[1];
              $ampm = "am";
              if ($hours > 12) {
                $hours = $hours-12;
                $ampm = "pm";
              } else if ($hours == 12) {
                $ampm = "pm";
              }
            } ?>
            <label class="input-group-text" for="ProgramHours">Time</label>
            <select class="form-select" id="ProgramHours" name="ProgramHours" onchange="checkampm()">
              <?php
              for ($hour = 9; $hour < 21; $hour++) {
                $printedhour = $hour;
                if ($hour > 12) {
                  $printedhour = $printedhour - 12;
                } ?>
              <option value="<?php echo $hour; ?>" <?php if ($printedhour == $hours) echo " selected" ?>><?php echo $printedhour; ?></option>
              <?php } ?>
            </select>
            <span class="input-group-text">:</span>
            <select class="form-select" name="ProgramMinutes" id="ProgramMinutes">
              <?php
              for ($minute = 0; $minute <= 3; $minute++) {
                $minutetotal = $minute * 15;
                if ($minutetotal == 0) {
                  $minutetotal = "00";
                } ?>
                <option value="<?php echo $minutetotal; ?>" <?php if ($minutetotal == $minutes) echo " selected" ?>><?php echo $minutetotal; ?></option>
                <?php } ?>
              </select>
            <span class="input-group-text" id="ampm"><?php echo $ampm; ?></span> 
          </div>
          <div class="input-group mb-3">
            <div class="btn-group" role="group">
                <input type="checkbox" class="btn-check" id="Sunday" name="Days" value="Sunday" autocomplete="off" <?php if (in_array("Sunday", $days)) echo " checked" ?>>
                <label class="btn" for="Sunday">Sunday</label> 

                <input type="checkbox" class="btn-check" id="Monday" name="Days" value="Monday" autocomplete="off" <?php if (in_array("Monday", $days)) echo " checked" ?>>
                <label class="btn" for="Monday">Monday</label> 

                <input type="checkbox" class="btn-check" id="Tuesday" name="Days" value="Tuesday" autocomplete="off" <?php if (in_array("Tuesday", $days)) echo " checked" ?>>
                <label class="btn" for="Tuesday">Tuesday</label> 

                <input type="checkbox" class="btn-check" id="Wednesday" name="Days" value="Wednesday" autocomplete="off" <?php if (in_array("Wednesday", $days)) echo " checked" ?>>
                <label class="btn" for="Wednesday">Wednesday</label> 

                <input type="checkbox" class="btn-check" id="Thursday" name="Days" value="Thursday" autocomplete="off" <?php if (in_array("Thursday", $days)) echo " checked" ?>>
                <label class="btn" for="Thursday">Thursday</label> 

                <input type="checkbox" class="btn-check" id="Friday" name="Days" value="Friday" autocomplete="off" <?php if (in_array("Friday", $days)) echo " checked" ?>>
                <label class="btn" for="Friday">Friday</label> 

                <input type="checkbox" class="btn-check" id="Saturday" name="Days" value="Saturday" autocomplete="off" <?php if (in_array("Saturday", $days)) echo " checked" ?>>
                <label class="btn" for="Saturday">Saturday</label> 
            </div>
          </div>
          <div class="input-group mb-3">
            <?php 
              if ($programid != "new") {
                preg_match("/([0-9]+)-([0-9]+)([my])/", $programinfo['AgeRange'], $ageinfo);
                $lowage = $ageinfo[1];
                $highage = $ageinfo[2];
                $monthsyears = $ageinfo[3];
              }
            ?>
            <span class="input-group-text">Age Range</span>
            <select class="form-select" id="lowage" name="LowAge" onchange="agechange('low')">
                  <?php
                  for ($age = 0; $age < 18; $age++) { ?>
              <option value="<?php echo $age; ?>"<?php if (isset($lowage) AND ($lowage == $age)) echo " selected" ?>><?php echo $age; ?></option>
                  <?php } ?>
            </select>
            <span class="input-group-text">-</span>
            <select class="form-select" id="highage" name="HighAge" onchange="agechange('high')">
                <?php
                  for ($age = 1; $age <= 18; $age++) { ?>
              <option value="<?php echo $age; ?>"<?php if (isset($highage) AND ($highage == $age)) echo " selected" ?>><?php echo $age; ?></option>
                  <?php } ?>
            </select>
            <select class="form-select" id="monthsyears" name="MonthsYears">
              <option value="m"<?php if (isset($monthsyears) AND ($monthsyears == "m")) echo " selected" ?>>Months</option>
              <option value="y"<?php if (isset($monthsyears) AND ($monthsyears == "y")) echo " selected" ?>>Years</option>
            </select>
          </div>
          <div class="input-group mb-3">
            <span class="input-group-text">Open Registration Minutes</span>
            <input type="number" class="form-control" name="SecondTierMinutes" value="<?php echo ($programid != "new") ? $programinfo['SecondTierMinutes'] : 5; ?>" min=0>
          </div>
          <div class="input-group mb-3">
            <span class="input-group-text">Room</span>
            <select class="form-select" name="LocationID" onchange="updateCapacityGrace()">
              <?php 
              $defaultcapacity = 0;
              $defaultgrace = 0;
              $defaultheld = 0;
              foreach ($locationinfo AS $id => $values) { ?>
              <option value="<?php echo $id; ?>"<?php if ($id == $programinfo['LocationID']) echo " selection"; ?>><?php echo $values['Description'] . " (Capacity: " . $values['Capacity'] . " + " . $values['Grace'] . ")"; ?></option>
              <?php
                if ($defaultcapacity == 0) {
                  $defaultcapacity = $values['Capacity'];
                } 
                if ($defaultgrace == 0) {
                  $defaultgrace = $values['Grace'];
                }
                if ($defaultheld == 0) {
                  $defaultheld = $values['DefaultHeld'];
                }
              } ?>
            </select>
          </div>
          <div class="input-group mb-3">
          <span class="input-group-text">Capacity</span>
            <input type="number" class="form-control" id="Capacity" name="Capacity" min="5" max="40" value="<?php echo ($programid != "new") ? $programinfo['Capacity'] : $defaultcapacity; ?>">
          </div>
          <div class="input-group mb-3">
            <span class="input-group-text">Grace Spaces</span>
            <input type="number" class="form-control" id="Grace" name="Grace" min="0" max="5" value="<?php echo ($programid != "new") ? $programinfo['Grace'] : $defaultgrace; ?>">
          </div>
          <div class="input-group mb-3">
            <span class="input-group-text">Tickets Reserved for In District</span>
            <input type="number" class="form-control" id="DefaultHeld" name="DefaultHeld" value="<?php echo ($programid != "new") ? $programinfo['DefaultHeld'] : $defaultheld; ?>" min=0>
          </div>
          <div class="form-check mb-3">
            <input class="form-check-input" type="checkbox" name="ChildOnly" value="1" id="ChildOnly" <?php if (($programid != "new") and ($programinfo['ChildOnly'] == 1)) {
              echo " checked";
            } ?> >
              <label class="form-check-label" for="ChildOnly">
                No adult tickets issued
              </label>
          </div>
          <input type="hidden" name="ProgramID" value="<?php echo $programid; ?>">
          <div class="input-group">
            <input class="btn btn-primary btn-lg" type="submit" value="<?php echo ($programid != "new") ? "Update " : "Create "; ?> Program" onclick="return validate()">
          </div>
          <a href="programs.php" class="btn btn-danger btn-lg" role="button">Cancel</a>
        </form>
              </div>
              </div>
        <?php if ($programid != "new") { ?>
          <hr>
            <div class="row">
              <div class="col-md-6 mx-auto">
                <div class="mt-3 text-center">
                  <form action="/cgi-bin/addystickprog.pl" method="POST">
                    <input type="hidden" name="ProgramID" value="<?php echo $programid; ?>">
                    <input type="hidden" name="action" value="archive">
                    <input class="btn btn-warning btn-lg" type="submit" value="Archive this Program">
                  </form>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-md-6 mx-auto">
                <div class="mt-3 text-center">
                  <form action="/cgi-bin/addystickprog.pl" method="POST">
                    <input type="hidden" name="ProgramID" value="<?php echo $programid; ?>">
                    <input type="hidden" name="action" value="delete">
                    <input class="btn btn-danger btn-lg" type="submit" value="Delete this Program (<?php echo $eventinfo['Total']; ?> Associated Event<?php if ($eventinfo['Total'] != 1) echo "s"; ?>)" onclick="return confirm('Are you sure you want to delete this program and its associated events.  Associated events won\'t be available for statistics.')">
                  </form>
                </div>
              </div>
            </div>
        <?php } ?>
        
       </div>

<?php

?>
</div>
    </main>
    <script src="/bootstrap/js/jquery.min.js"></script>
<script src="/bootstrap/js/popper.js"></script>
<script src="/bootstrap/js/bootstrap.min.js"></script>
  </body>
</html>