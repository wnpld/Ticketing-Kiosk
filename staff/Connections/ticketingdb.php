<?php
# FileName="Connection_php_mysql.htm"
# Type="MYSQL"
# HTTP="true"
$hostname_ticketingdb = "";
$database_ticketingdb = "";
$username_ticketingdb = "";
$password_ticketingdb = "";
try {
    $ticketingdb = new mysqli($hostname_ticketingdb, $username_ticketingdb, $password_ticketingdb, $database_ticketingdb);
} catch (Exception $e) {
    echo "Service unavailable";
    echo "message: " . $e->getMessage();
    exit;
}

?>
