# Common.pm
# Variables which are used across multiple scripts are stored here
package Common;
use strict;

#Server Protocol (http or https)
our $serverprotocol = "http";

#Local server name
our $serveraddress = "";

#Web directory hosting the management pages
our $managementdir = "";

#SIP Connection Data
our $sipserver = "";
our $siplogin = "";
our $sippassword = "";
our $siplocation = "";

#SQL Connection Data
our $dbuser = "";
our $dbpassword = "";
our $databasename = "";

#Hash Salt Value
#Should be large random string of junk
our $hashsalt = "";
