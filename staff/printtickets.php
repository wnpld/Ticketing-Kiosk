<?php
require_once('Connections/ticketingdb.php');
require_once('common.php');
$ticketid = 0;
$adults = 0;
$children = 0;

if (isset($_REQUEST['ticketid'])) {
    if (is_numeric($_REQUEST['ticketid'])) {
        $ticketid = $_REQUEST['ticketid'];
    } else {
        header("Location: $protocol://$domain/$currentdir/");
    }
} else {
    header("Location: $protocol://$domain/$currentdir/");
}

if (isset($_REQUEST['adults'])) {
    if (is_numeric($_REQUEST['adults'])) {
        $adults = $_REQUEST['adults'];
    }
}

if (isset($_REQUEST['children'])) {
    if (is_numeric($_REQUEST['children'])) {
        $children = $_REQUEST['children'];
    }
}

$reprint = false;
if (isset($_REQUEST['reprint'])) {
    if ($_REQUEST['reprint'] == "true") {
        $reprint = true;
    }
}

mysqli_select_db($ticketingdb, $database_ticketingdb);

$query_event = sprintf("SELECT HEX(t.identifier) AS id, t.Adults, t.Children, tp.ProgramName, tp.ProgramTime, te.EventID, tl.LocationDescription FROM Tickets t INNER JOIN TicketedEvents te ON t.EventID = te.EventID INNER JOIN TicketedPrograms tp ON te.ProgramID = tp.ProgramID INNER JOIN TicketLocations tl ON tp.LocationID = tl.LocationID WHERE t.TicketID = $ticketid");
$event = mysqli_query($ticketingdb, $query_event) or die(mysqli_error($ticketingdb));
$eventinfo = mysqli_fetch_assoc($event);

$rawtime = strtotime($eventinfo['ProgramTime']);
$id = $eventinfo['id'];
$date = date("F j, Y");
$time = date("g:i a", $rawtime);
$code = date("Y-n-j-G-i-") . substr($id, -8, 8);

$alladults = $eventinfo['Adults'];
$allchildren = $eventinfo['Children'];
$agerange = $eventinfo['AgeRange'];

if ($reprint) {
    $adultcount = $alladults;
    $childcount = $allchildren;
} else {
    $adultcount = $adults;
    $childcount = $children; 
}

$emojiid;
$emojiseed = $eventinfo['EventID'];
$emojiseed += 100;
$emojiseed = $emojiseed % 33;
$emojiseed++;
if ($emojiseed < 10) {
    $emojiid = "images/emoji0" . $emojiseed . ".png";
} else {
    $emojiid = "images/emoji" . $emojiseed . ".png";
}

?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="scaffolded-by" content="https://gihub.com/dart-lang/sdk">
        <link id="bs-css" href="/bootstrap/css/bootstrap.min.css" rel="stylesheet">
        <link href="print.css" media="print" rel="stylesheet">
        <script src="/jquery/jquery-3.7.1.min.js"></script>
        <script defer src="ticketprint.js"></script>
    </head>
    <body>
        <div class="main">
            <form>
                <input type="hidden" id="children" value="<?php echo $childcount; ?>">
                <input type="hidden" id="adults" value="<?php echo $adultcount; ?>">
                <input type="hidden" id="allchildren" value="<?php echo $allchildren; ?>">
                <input type="hidden" id="alladults" value="<?php echo $alladults; ?>">
            </form>
            <div class="container" id="print">
                <h1 id="eventprint"><?php echo $eventinfo['ProgramName']; ?></h1>
                <h2 id="timeprint"><?php echo $time; ?></h2>
                <h3 id="roomprint"><?php echo $eventinfo['LocationDescription']; ?></h3>
                <p id="dateprint"><?php echo $date; ?></p>
                <div id="ageprint" class="audience"></div>
                <p id="countprint"></p>
                <p id="codeprint"><?php echo $code; ?></p>
                <img src="<?php echo $emojiid; ?>">
            </div>
        </div>
    </body>
</html>