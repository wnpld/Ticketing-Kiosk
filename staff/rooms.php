<?php require_once('Connections/ticketingdb.php');
require_once('common.php');

mysqli_select_db($ticketingdb, $database_ticketingdb);
$query_roomlist = $ticketingdb->prepare("SELECT LocationID, LocationDescription, LocationCapacity, GraceSpaces, DefaultHeld FROM TicketLocations ORDER BY LocationID ASC");
$query_roomlist->execute() or die(mysqli_error($ticketingdb));
$roomlist = $query_roomlist->get_result();
$rooms = array();
while ($row = mysqli_fetch_assoc($roomlist)) {
  $id = $row['LocationID'];
  foreach ($row as $key => $value) {
    if ($key != 'LocationID') {
      $rooms[$id][$key] = $value;
    }
  }
}

?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Room Management</title>
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
	    <a class="nav-link active" href="#">Room Management</a>
	  </li>
	</ul>
      </div>
</div>
          </nav>
    <main role="main">
      <div class="container">
        <h1>Room Management</h1>
        <p>This page is for modifying preferences for or adding a room.  These settings determine default values for programs, although the capacity, grace and reserved numbers for a given program can be adjusted to be different from that of the room.  Deleting a room is not possible from this page, so if you really need to do that talk to the IT Manager.</p>
        <ul>
          <li><strong>Capacity</strong>: The official number of patrons allowed in a room for a program.</li>
          <li><strong>Grace Spaces</strong>: The amount of padding that is allowed in ticket allocation to exceed capacity to meet demand (e.g. for an adult with a child will be allowed into a room with a capacity of 40 and 39 booked spaces, there needs to be at least 1 grace space available).</li>
          <li><strong>Default Reserved Spaces</strong>: The number of spaces reserved exclusively for Winnetka-Northfield patrons.</li>
</ul>
        <div class="mx-auto"><a class="btn btn-primary btn-lg" href="editroom.php">Create a New Room</a></div>
<table class="table table-striped">
  <thead>
    <tr>
      <th>Room Name</th>
      <th>Capacity</th>
      <th>Grace Spaces</th>
      <th>Default Reserved Spaces</th>
    </tr>
  </thead>
  <tbody>
    <?php foreach ($rooms as $id => $values) { ?>
      <tr>
        <td><a href="editroom.php?roomid=<?php echo $id; ?>"><?php echo $values['LocationDescription'] ?></a></td>
        <td><?php echo $values['LocationCapacity']; ?></td>
        <td><?php echo $values['GraceSpaces']; ?></td>
        <td><?php echo $values['DefaultHeld']; ?></td>
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
