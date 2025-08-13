# Library Storytime/Event Kiosk

## Description
This is a project designed to be used with a standalone kiosk running a web browser with a barcode scanner and receipt printer attached.  In our case we are using a computer running Kubuntu and Chromium with a kiosk plugin installed, although many different configurations should work.

The parts here are mostly server-side components although there is a Perl script and an image directory which need to run on the kiosk itself.  This is the revised version of the software created in August 2025.  It has been written to directly solve the problems we needed to address although there are definitely limitations to its capabilities.  Notably it will not handle ticket race conditions very well, so it is strongly advised that anyone using this software in its current form not have more than one kiosk running at a time as two kiosks running simultaneously could result in too many tickets being issued.

The primary goal we are trying to achieve with this is the prioritization of local cardholders over non-residents, while still allowing non-residents to get tickets for events once a certain amount of time has been reached.

The staff interface has been granted wide latitude in overriding tickets.  With this version there is no authentication implemented for the staff portion.  It's assumed that this is running on a staff network and that the kiosks themselves will have extremely restricted interfaces.

## Installation
The YouthTicketing SQL file is intended to be added to a database of that name running on a MySQL or MariaDB server on the same server as the web server hosting this solution.  It should be possible to run a separate MySQL server, but you'll need to adjust the connection protocols to be using a remote server.

The remaining files will require Perl, the web server of your choice with a PHP interpreter (tested on PHP 8), and Dart (tested on version 3.5) development tools to be installed (although the Dart compiler can be installed on a different computer if you'd prefer to go that route).  These are in three folders which go into different places:
* The cgi folder includes Perl scripts and should be in the CGI directory for your web server.  This includes some code which I did not write which is located in the Biblio-SIP2-master directory.  As of the time of this writing the original code project is located at https://github.com/dpavlin/Biblio-SIP2.  This code is used for connecting to a SIP2 server (in our case Polaris) for card authentication.  If you are using a different ILS, the code for this may or may not work as intended.
* The public folder is the folder for the web server which is used by the kiosk installation.  You can rename this as you'd like.
* The staff folder is the folder for the web server for staff administration of events and tickets.  You can rename this as you'd like.

The HTML and PHP relies on Bootstrap (tested with version 5) and JQuery.  In both cases we are using locally installed copies and that's reflected in the code.  You can change those to point to remote libraries or download libraries of your choosing.  Make sure that you update the appropriate paths in those files.

Both the public and staff folders use Javascript derived from compiled Dart code.  The Dart code is included here but not the Javascript, since you will need to adjust the Dart code for your purposes before compiling to Javascript.  I was not imaginitive when compiling the Dart code for these pages, so the default compile to "out.js" is all that is required for both of these directories unless you intend to adjust the PHP/HTML pages which call those scripts.

The following files will need to be customized prior to deployment:
* cgi/Common.pm
* cgi/bcval.pl (particularly in the section around line 100)
* public/globals.dart
* staff/Connections/ticketingdb.php
* staff/common.php

## Kiosk Software Installation and Configuration
The kiosk itself needs a Perl script installed to handle printing the receipts.  In the original implementation of this project this was just handled by the web browser.  A number of problems resulted from this, not least of these being the fact that receipt printers need somewhat difficult to find drivers in Linux and CUPS is in the process of eliminating the use of standard print drivers.

The solution here was to set up a Perl script which can communicate with any ESC/POS compatible receipt printer and set that up as the handler of a custom protocol which is invoked by a JavaScript command at the time of printing.  In our implementation this was done on a kiosk running Kubuntu and Firefox connected to a Citizen CT-S310II receipt printer.  If your configuration varies you will likely need to adjust the script and the location of the image files it relies on.

The kioskprint Perl script should be installed in a location in the user's path.  In our case we installed it in /usr/local/bin.  It uses the Printer::ESCPOS module which is available through CPAN.  On Linux you will need to make sure that you have **make** installed via your package manager, and it's a good idea to install as many of the dependencies for Printer::ESCPOS via the package manager as possible to make the installation of the module quicker in CPAN.  You can find more information and the list of dependencies at https://metacpan.org/dist/Printer-ESCPOS.

The Image::Scale and DateTime Perl modules also need to be installed.

Since the kioskprint script is run by the kiosk user and it needs to communicate directly to the receipt printer, make sure that the kiosk user has rights to use the printer.  In our case that meant adding the kiosk user to the **lp** group.

You will also need to put copy the **kioskdata** directory in a place that the kiosk user can read but cannot write to.  We moved it to /opt/ and set the permissions to 775.

Finally, you will need to configure your web browser (in my experience Firefox does this best) and possibly the window manager to handle the custom **rcptprt** protocol used so that it runs the Perl script.  The following settings changed in **about:config** seem to work well:
* network.protocol-handler.app.rcptprt: /usr/local/bin/kioskprint
* network.protocol-handler.expose.rcptprt: true
* network.protocol-handler.external.rcptprt: true

It may be necessary to establish a handler on the OS level as well.  This will vary by OS (and in the case of Linux, by Window Manager).

## Pull Requests
This code has been developed for use by the Winnetka-Northfield Public Library District.  Feel free to fork and reuse it as you see fit.  If you would like to contribute to this and the features are ones that I think would contribute to the project without interfering with our own use case I'd be happy to incorporate them.

My personal experience with git and github is limited, so patience would be appreciated.

## License 
Copyright is not claimed for the Biblio-SIP2 library nor for any of the images.  Font images are derived from Arial, Segoe UI, and Symbola.  Flag files are from https://flagicons.lipis.dev, which is also on GitHub at https://github.com/lipis/flag-icons.

### MIT License
Copyright 2024 Winnetka-Northfield Public Library District

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Credits
* Thank you to @dpavlin for the Biblio-SIP2 project
* Thank you to @lipis for the flag icons project
* I am @wnklibms (Mark Swenson) on github for @wnpld
