import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;
import 'package:intl/intl.dart';

//Main function.  Estabilishes/resets language value and global button functions
Future<void> main() async {
    //If the default language needs to be changed, it should be changed here and in the globals file
    globals.language = "english";

    //These languages need to specified also in the globals file
    document.querySelector('#english')?.onClick.listen((MouseEvent e) => changeLanguage(e, "english"));
    document.querySelector('#spanish')?.onClick.listen((MouseEvent e) => changeLanguage(e, "spanish"));
    document.querySelector('#russian')?.onClick.listen((MouseEvent e) => changeLanguage(e, "russian"));
    document.querySelector('#polish')?.onClick.listen((MouseEvent e) => changeLanguage(e, "polish"));
    document.querySelector('#chinese')?.onClick.listen((MouseEvent e) => changeLanguage(e, "chinese"));
    document.querySelector('#tradchinese')?.onClick.listen((MouseEvent e) => changeLanguage(e, "tradchinese"));

    //This button is for switching to manual card entry
    document.querySelector('#manualentry')?.onClick.listen((MouseEvent e) => manualEntry(e));

    //These buttons are used for manual card entry
    document.querySelector('#one')?.onClick.listen((MouseEvent e) => typeNumber(e, "1"));
    document.querySelector('#two')?.onClick.listen((MouseEvent e) => typeNumber(e, "2"));
    document.querySelector('#three')?.onClick.listen((MouseEvent e) => typeNumber(e, "3"));
    document.querySelector('#four')?.onClick.listen((MouseEvent e) => typeNumber(e, "4"));
    document.querySelector('#five')?.onClick.listen((MouseEvent e) => typeNumber(e, "5"));
    document.querySelector('#six')?.onClick.listen((MouseEvent e) => typeNumber(e, "6"));
    document.querySelector('#seven')?.onClick.listen((MouseEvent e) => typeNumber(e, "7"));
    document.querySelector('#eight')?.onClick.listen((MouseEvent e) => typeNumber(e, "8"));
    document.querySelector('#nine')?.onClick.listen((MouseEvent e) => typeNumber(e, "9"));
    document.querySelector('#zero')?.onClick.listen((MouseEvent e) => typeNumber(e, "0"));
    document.querySelector('#backspace')?.onClick.listen((MouseEvent e) => deleteNumber(e));
    document.querySelector('#manualsubmit')?.onClick.listen((MouseEvent e) => checkNumber(e, barcode: document.querySelector('#enteredbarcode')?.text));
    document.querySelector('#manualcancel')?.onClick.listen((MouseEvent e) => resetPage(e));

    //This button is for cancelling out from the event selection screen
    document.querySelector('#eventcancel')?.onClick.listen((MouseEvent e) => resetPage(e));

    /* These buttons are for cancelling out of the ticket selection screen
    If someone has a choice of ticketted events the button returns to the event selection screen
    If there is only a single choice of tickets, the button resets the page */
    document.querySelector('#ticketscancel')?.onClick.listen((MouseEvent e) => backToEvents(e));

    /*Send the barcode "update" to the barcode checking script to get updated program
    information.  The script knows not to investigate this barcode. */
    String initialStatus = await checkBarcode("update");
    try {
        var progInfo = jsonDecode(initialStatus);
        /*Check the decoded json for any kind of error, which will be in the status
        field.  At this point, there should be no SIP status messages, only "update" or 
        DBI error statuses.  Look for DBI errors and handle them. */
        String? error = progInfo['error'];
        if (error != null) {
            //DBI error code - better find out what this is
            String? errorDetail = progInfo['detail'];
            if (errorDetail == null) {
                errorDetail = "unknown";
            }
            reportError(error, errorDetail, "unknown");
        }
        if (progInfo['events'].length == 0) {
            //If there are no events left for this day, just display a closed message
            closeKiosk();
        } else {
            /*Show basic information about today's remaining events*/
            for (int x = 0; x < progInfo['events'].length; x++) {
                var eventinfo = progInfo['events'][x];
                String program = eventinfo['program'];
                String time = prettyTime(eventinfo['time']);
                String ages = eventinfo['ages'];
                if (eventinfo['age_qualifier'] == "y") {
                    ages = ages + "<span class=\"yearsterm\"> years</span>"; 
                } else {
                    ages = ages + "<span class=\"monthsterm\"> months</span>";
                }
                int capacity = eventinfo['capacity'];
                int reserved = eventinfo['oodtickets'] + eventinfo['dtickets'];
                int grace = eventinfo['grace'];
                String ticketstatus;
                if (((capacity + grace) - reserved) >= 4) {
                    ticketstatus = "<span class=\"badge rounded-pill text-bg-success ticketsbadge\">Tickets Available</span>";
                } else {
                    ticketstatus = "<span class=\"badge rounded-pill text-bg-danger noticketsbadge\">No Tickets Remaining</span>";
                }
                String eventcode = "<div>" + ticketstatus + " " + time + ": " + program + " (" + ages + ")";
                document.querySelector('#eventlist')?.appendHtml(eventcode);
            }
            /*Registration Delay is used for restricting registration for non-district
            cards and phone numbers.  It is a required field so it's set statically in the
            SQL query as 8 hours for district patrons.  It uses the program's delay value
            for non-district cards*/
            globals.registrationdelay = progInfo['events'][0]['registrationdelay'];

            //Watch for typed numbers.  These are expected to come from a barcode reader.        
            List<String> typed = [];
            List<String> startcode = [];
            window.onKeyDown.listen((event) async {
                /* Some codabar barcodes start and end with a letter A-D.  Many scanners
                can be set to ignore these, but the scanners we are using do not. The 
                exp RegExp is used to identify one of these letters at the start of a barcode.
                If it finds it, it is stored in startcode and then each character after that
                is monitored to see if it matches the startcode.  If it does, the numbers
                between the letters get sent.  For other barcodes, the enter key is the
                send trigger. */
                RegExp exp = RegExp(r'[ABCD]');
                String? entered = event.key;
                if (entered != null) {
                    if (entered == "Enter") {
                        String barcode = typed.join();
                        //The sendNumber function passes the number on for checking
                        sendNumber(barcode);
                    } else {
                        if (typed.length == 0) {
                            bool match = exp.hasMatch(entered);
                            if (match == true) {
                                startcode.add(entered);
                            } else if (entered != "Shift") {
                                typed.add(entered);
                            }
                        } else {
                            if (startcode.length != 0) {
                                bool match = exp.hasMatch(entered);
                                if ((match != true) & (entered != "Shift")) {
                                    typed.add(entered);
                                } else {
                                    String barcode = typed.join();
                                    sendNumber(barcode);
                                }
                            } else {
                                typed.add(entered);
                            }
                        }
                    }
                }
            });
        } 
    } on FormatException catch (e) {
        reportError(e.toString(), initialStatus, "jsonexception");
    }   
}

/*changeLanguage updates all established language specific blocks with a new
chosen language.  Program event names and descriptions are not handled, but
almost all other text is.*/
void changeLanguage(MouseEvent event, String language) {
    //Set the new global language based on the submitted language string
    globals.language = language;

    //Set all of the text instances to the new language.
    document.querySelector('#scantext')?.text = globals.scanBarcode?[language];
    document.querySelector('#manualentry')?.text = globals.manualEntry?[language];
    document.querySelector('#errorheader')?.text = globals.closedHeader?[language];
    document.querySelector('#errorinfo')?.text = globals.closedText?[language];
    document.querySelector('#manualtext')?.text = globals.manualText?[language];
    String? description = globals.manualDescription[language];
    if (description != null) {
        description = description.replaceAll("###", globals.registrationdelay.toString());
        document.querySelector('#manualdescription')?.text = description;
    } else {
        document.querySelector('#manualdescription')?.text = "No description available (something went wrong)";
    }
    document.querySelector('#manualcancel')?.text = globals.manualCancel[language];
    document.querySelector('#eventcancel')?.text = globals.seCancel[language];
    document.querySelector('#ticketscancel')?.text = globals.ticketsCancel[language];
    document.querySelector('#eventcancel')?.text = globals.eventCancel[language];
    document.querySelector('#seheader')?.text = globals.selectEvent[language];
    document.querySelector('#stheader')?.text = globals.selectTickets[language];
    document.querySelector('#ticketsoutspan')?.text = globals.ticketsOut[language];
    document.querySelector('#genticketsoutspan')?.text = globals.noTicketsNowButton[language];
    document.querySelector('#ticketlimitspan')?.text = globals.limitReached[language];
    ElementList classList = document.querySelectorAll('.monthsterm');
    if (classList != null) {
        var it = classList.iterator;
        while (it.moveNext()) {
            it.current.text = globals.monthsTerm[language];
        }
    } 
    classList = document.querySelectorAll('.yearsterm');
    if (classList != null) {
        var it = classList.iterator;
        while (it.moveNext()) {
            it.current.text = globals.yearsTerm[language];
        }
    }
    document.querySelector('#seheader')?.text = globals.selectEvent[language];
    document.querySelector('#stheader')?.text = globals.selectTickets[language];
    document.querySelector('#adultticketsheader')?.text = globals.adultTicketsHeader[language];
    String? adultnote = querySelector('#adultticketsnote')?.text;
    if (adultnote != null ) {
        if (adultnote.length > 0) {
            document.querySelector('#adultticketsnote')?.text = globals.adultTicketsNote[language];
        }
    }
    document.querySelector('#childticketsheader')?.text = globals.childTicketsHeader[language];
    document.querySelector('#cnotei')?.text = globals.childNoteI[language];
    document.querySelector('#cnoteii')?.text = globals.childNoteII[language];
    document.querySelector('#formbutton')?.text = globals.requestTickets[language];
    document.querySelector('#eventlistheader')?.text = globals.remainingEvents[language];
    classList = document.querySelectorAll('.ticketsbadge');
    if (classList != null) {
        var it = classList.iterator;
        while (it.moveNext()) {
            it.current.text = globals.ticketsAvailable[language];
        }
    }
    classList = document.querySelectorAll('.noticketsbadge');
    if (classList != null) {
        var it = classList.iterator;
        while (it.moveNext()) {
            it.current.text = globals.ticketsOut[language];
        }
    }
    document.querySelector('#manualsubmit')?.text = globals.manualSubmit[language];
    document.querySelector('#finishheader')?.text = globals.finishHeader[language];
    document.querySelector('#finishtext')?.text = globals.finishText[language];

    //These are for error elements which may or may not exist at different points of operation
    document.querySelector('#cardOODheader')?.text = globals.cardOODheader?[language];
    String? oodinfo = globals.cardOODinfo[language];
    if (oodinfo != null) {
        oodinfo = oodinfo.replaceAll('###', globals.registrationdelay.toString());
        document.querySelector('#cardOODinfo')?.text = oodinfo;
    } else {
        document.querySelector('#cardOODinfo')?.text = "No translation available (something went wrong)";
    }
    document.querySelector('#phoneErrorheader')?.text = globals.phoneErrorheader?[language];
    String? phoneinfo = globals.phoneErrorinfo[language];
    if (phoneinfo != null) {
        phoneinfo = phoneinfo.replaceAll('###', globals.registrationdelay.toString());
        document.querySelector('#phoneErrorinfo')?.text = phoneinfo;
    } else {
        document.querySelector('#phoneErrorinfo')?.text = "No translation available (something went wrong)";
    }
    document.querySelector('#barcodeErrorheader')?.text = globals.barcodeErrorheader?[language];
    document.querySelector('#barcodeErrorinfo')?.text = globals.barcodeErrorinfo?[language];
    document.querySelector('#alreadyTicketedheader')?.text = globals.alreadyTicketedheader?[language];
    document.querySelector('#alreadyTicketedinfo')?.text = globals.alreadyTicketedinfo?[language];
    document.querySelector('#noTicketsNowheader')?.text = globals.noTicketsNowheader?[language];
    String? ticketsnow = globals.noTicketsNowinfo[language];
    if (ticketsnow != null) {
        ticketsnow = ticketsnow.replaceAll('###', globals.registrationdelay.toString());
        document.querySelector('#noTicketsNowinfo')?.text = ticketsnow;
    }

    return;
}

//This function changes the screen from the scanning page to the manual entry page
void manualEntry(MouseEvent event) {
    globals.scanblock?.style.display = "none";
    globals.manualblock?.style.display = "block";
}

void typeNumber(MouseEvent event, String number) {
    String? barcode = document.querySelector('#enteredbarcode')?.text;
    globals.barcodespan?.classes.remove("placeholder");
    globals.barcodespan?.classes.add("alert");
    globals.barcodespan?.classes.add("alert-success");
    if (barcode != null) {
        barcode += number;
        document.querySelector('#enteredbarcode')?.text = barcode;
    }
    return;
}

void deleteNumber(MouseEvent event) {
    String? barcode = document.querySelector('#enteredbarcode')?.text;
    if (barcode != null) {
        if (barcode.length > 1) {
            document.querySelector('#enteredbarcode')?.text = barcode.substring(0, barcode.length - 1);
        } else {
            document.querySelector('#enteredbarcode')?.text = "";
            globals.barcodespan?.classes.remove("alert");
            globals.barcodespan?.classes.remove("alert-success");
            globals.barcodespan?.classes.add("placeholder");
        }
    }
    return;
}

//Displays that the kiosk is closed because there are no more events
Future<void> closeKiosk() async {
    String? language = globals.language;
    if (language == null) {
        language = "english";
    }
    globals.scanblock?.style.display = "none";
    globals.errorblock?.style.display = "block";
    document.querySelector("#errorheader")?.text = globals.closedHeader[language];
    document.querySelector("#errorinfo")?.text = globals.closedText[language];
}

/*checkNumber handles the a mouseEvent and then passes the barcode
on to be checked.*/
void checkNumber(MouseEvent event, {String? barcode}) {
    if (barcode == null) {
        return;
    } else {
        sendNumber(barcode);
    }
}

/*sendNumber submits a card number to a Perl script for
checking and collects relevant event data*/
Future<void> sendNumber(String barcode) async {
    String? language = globals.language;
    String bcStatus = await checkBarcode(barcode);
    try {
       var bcResponse = jsonDecode(bcStatus);
        /*Check the decoded json for any kind of error, which will be in the status
        field.  Accepted normal values are: 0 and update.  If there's a database error,
        there will be no fields other than status and detail.  Otherwise it's some 
        kind of SIP status message. */
        String? error = bcResponse['error'];
        if (error != null) {
            //DBI status code - better find out what this is
            String? errorDetail = bcResponse['detail'];
            if (errorDetail == null) {
                errorDetail = "unknown";
            }
            reportError(error, errorDetail, "dberror");
        }

        String? status = bcResponse['status'];
        String sipstatus = "";
        int? valid = bcResponse['valid'];
        if (valid == null) {
            valid = -1;
        }
        if (status != null) {
            if ((status != "update") && (status != "ok") && (status != "phone")) {
                if (valid > 0) {
                    /* SIP status code - may be important.  Display this in the footer. */
                    if (bcResponse['error'] != null) {
                        sipstatus = bcResponse['error'];
                    }
                    globals.footertext?.style.display = "block";
                    if (sipstatus == "This software is not logged in to the SIP Service") {
                        document.querySelector('#footer')?.text = "There was a problem connecting to the catalog system to verify your card.  Please see a librarian.";
                    } else if (sipstatus != "") {                    
                        document.querySelector('#footer')?.text = sipstatus;
                    }
                } else {
                    document.querySelector('#footer')?.text = status;
                }
            }
        } else {
            //If the status field is null, something's not right.  Just go to the error page
            reportError("Null Status Error", "No status was reported back from the barcode/phone number check.  This indicates some kind of serious problem.", "nullstatus");
        }
        int library = bcResponse['library'];
        int fine = bcResponse['fine'];
        String bchash = bcResponse['id'];
        var ticketlist = bcResponse['tickets'];
        var events = bcResponse['events'];

        /* When tallying events, the Perl script takes district status into
        account.  Each time this page loads it gets an updated list of upcoming
        events, so it should be pretty up-to-date.  If there are no events, we're
        assuming that it's an out of district card. */
        bool eventsAvailable = false;
        if (events != null) {
            if (events.length > 0) {
                eventsAvailable = true;
            }
        }

        if (valid >= 1 && eventsAvailable) {
            checkAvailability(bchash, events, ticketlist, library);
        } else if (valid == 1 && eventsAvailable == false) {
            String? errorheader = globals.cardOODheader[language]; 
            String? errorinfo = globals.cardOODinfo[language];
            if (errorheader == null) {
                errorheader = "Out of District Library Card";
            }
            if (errorinfo == null) {
                errorinfo = "No tickets are currently available for out-of-district users.  Check back ### minutes before the program starts.";
            }
            errorinfo = errorinfo.replaceAll("###", globals.registrationdelay.toString());
            reportError(errorheader, errorinfo, "cardOOD", 10);                
        } else if (valid == 2 && eventsAvailable == false) {
            String? errorheader = globals.phoneErrorheader[language];
            String? errorinfo = globals.phoneErrorinfo[language];
            if (errorheader == null) {
                errorheader = "Phone Number Entered";
            }
            if (errorinfo == null) {
                errorinfo = "Phone numbers can only be used to obtain tickets ### minutes before the start of the next program.";
            }
            errorinfo = errorinfo.replaceAll("###", globals.registrationdelay.toString());
            reportError(errorheader, errorinfo, "phoneError", 10);
        } else {
            window.location.reload();
/*
            The below code provides an error with a bad scan or invalid card.
            Bad scans are frequent enough that this is likely unhelpful and it's better
            to just reload the page, but I'm leaving this in here in case more feedback is 
            required with invalid card entries.
            ---
            String? errorheader = globals.barcodeErrorheader[language];
            String? errorinfo = globals.barcodeErrorinfo[language];
            if (errorheader == null) {
                errorheader = "The card scanned was not a valid library card.  Please use a valid card.";
            }
            if (errorinfo == null) {
                errorinfo = "Double-check the card that you scanned or entered to make sure that it was your current library card.  If you entered a phone number, make sure to enter the entire ten-digit phone number.";
            }
            errorinfo += " (" + barcode + ")";
            reportError(errorheader, errorinfo, "barcodeError", 10);
            */
        }
    } on FormatException catch (e) {
        reportError(e.toString(), bcStatus, "jsonexception");
    }
}

//Forces a page reload, resetting the application
void resetPage(MouseEvent event) {
    window.location.reload();
}

/*checkBarcode sends a submitted barcode to the perl script that checks with
the SIP server and also gets event information from the SQL server. It returns
resulting relevant information*/
Future<String> checkBarcode(String barcode) async {
    var url = Uri.http(globals.serverurl, globals.validatescript);
    var jsonresponse = await http.post(url, headers: {'Access-Control-Allow-Origin': '*'}, body: {'bc': barcode});
    String response = jsonresponse.body;
    return response;
  }

/*checkAvailability processes the result of a barcode check with the accompanying
event information and determines what events the submitted barcode is eligible for,
based on the results.*/
Future<void> checkAvailability(String bchash, var events, var ticketlist, int library) async {
    String? language = globals.language;
    int reloadDelay = 10; //This is the amount of delay to wait before refreshing the page
                          //It will be increased if there are valid events to choose from

    //If there are multiple events in the result prepare the screen for choosing an event
    globals.scanblock?.style.display = "none";
    globals.manualblock?.style.display = "none";
    globals.seblock?.style.display = "block";

    /*These classes are used for turning buttons on and off.
    an off button is used to identify that a program is happening, but is not
    available for the user for some reason.*/ 
    String enabledButtonClass = "btn btn-primary btn-xlg";
    String disabledButtonClass = "btn btn-secondary btn-xlg";

    /*anyeventmatch set to true will block registration for any additional
    events if the user is already registered for one.  Set to false, they will
    only be prevented from registering from an event they are already registered for
    or for an event which is full.*/
    bool anyeventmatch = true;

    //Hitting Enter extra times can keep running this and adding elements
    //Reset the HTML before running
    document.querySelector('#eventinfo')?.setInnerHtml("");

    //Loop through all of the events
    for (int x = 0; x < events.length; x++) {
        int capacity = events[x]['capacity'];
        int grace = events[x]['grace'];
        int oodtickets = events[x]['oodtickets'];
        int dtickets = events[x]['dtickets'];
        int ticketsheld = events[x]['ticketsheld'];
        int tickets = oodtickets + dtickets;
        int openminutes = events[x]['registrationdelay'];
        String time = events[x]['time'];

        if (library < 6) {
            //If this is an OOD card
            final rightnow = DateTime.now();
            final hourmin = time.split(':');
            int hour = int.parse(hourmin[0]);
            int minute = int.parse(hourmin[1]);
            minute -= openminutes;

            var windowstart = DateTime(rightnow.year, rightnow.month, rightnow.day, hour, minute);
            if (rightnow.compareTo(windowstart) < 0) {
                //We not in the window
                //Tickets are restricted
                tickets = ticketsheld + oodtickets;
            } 
        }

       /*Obtain a capacity status value from the capacityCheck function
        A capacity status of 2 means no restrictions.
        A capacity status of 1 means that the event is almost full, so only 1 adult
        ticket will be issued.
        A capacity status of 0 means that there is no remaining capacity.
        A capacity status of -1 (not obtained directly through this function) means
        that the user has hit an event maximum and can't register for additional events.*/
        int capStatus = capacityCheck(capacity, grace, tickets, library);

        /*Ticketlist contains a list of the events for which an identifier
        has been issued tickets for the current day.  A length of 0 means that
        the identifier hasn't been issued any tickets.*/
        if (ticketlist.length > 0) {
            if (anyeventmatch == true) {
               capStatus = -1;
            } else {
                /*This for loop checks to see if a user has already registered
                for a specific event.  It assumes that there is only one event
                at any given time.*/
                for (int y = 0; y < ticketlist.length; y++) {
                    if (ticketlist[y] == events[x]['time']) {
                        capStatus = -1;
                    }
                }
            }
        }
        //Now that this comparison has been done, create a pretty time
        String formattedTime = prettyTime(events[x]['time']);

        //Start building the string which will be put into an event selection button.
        String programInfo = formattedTime + ' - ' + events[x]['program'] + ' (' + events[x]['ages'].toString();

        //Age qualifier indicates whether an age is in months or years.
        String? agequal = events[x]['age_qualifier'];
        if (agequal != null) {
            if (agequal == "m") {
                String? monthsterm = globals.monthsTerm[language];
                if (monthsterm != null) {
                    programInfo += "<span class=\"monthsterm\">" + monthsterm + "</span>";
                } else {
                    programInfo += "<span class=\"monthsterm\"> months</span>";
                }
            } else {
                String? yearsterm = globals.yearsTerm[language];
                if (yearsterm != null) {
                    programInfo += "<span class=\"yearsterm\">" + yearsterm + "</span>";
                } else {
                    programInfo += "<span class=\"yearsterm\"> years</span>";
                }
            }
        } else {
            //Don't know why this would happen, but just assume years
            agequal = "y";
            String? yearsterm = globals.yearsTerm[language];
            if (yearsterm != null) {
                programInfo += "<span class=\"yearsterm\">" + yearsterm + "</span>";
            } else {
                programInfo += "<span class=\"yearsterm\"> years</span>";
            }
        }
        programInfo += ') - ' + events[x]['location'];

        /* As long as capacity status is positive, allow the user to get tickets */
        if (capStatus > 0) {
            String eventid = events[x]['eventid'];
            String eventname = events[x]['program'];
            String eventtime = formattedTime;
            String eventages = events[x]['ages'];
            String eventlocation = events[x]['location'];
            String eventagequal = events[x]['age_qualifier'];
            String buttonid = "eventbutton" + x.toString();
            String button = '<button id="' + buttonid + '" class="' + enabledButtonClass + ' mb-1">' + programInfo + '</button>';
            document.querySelector('#eventinfo')?.appendHtml(button);
            document.querySelector('#' + buttonid)?.onClick.listen((MouseEvent e) => chooseTickets(e, bchash, eventid, eventtime, eventname, eventlocation, eventages, eventagequal, capStatus));
            reloadDelay = 90;
        } else if (capStatus == -1) {
            /* A negative capacity status creates an unclickable button with program information
            as well as telling the user that their ticket limit has been reached for the day. */
            String? limitReached = globals.limitReached[language];
            String button;
            if (limitReached != null) {
                button = '<button type="button" class="' + disabledButtonClass + ' mb-1" disabled>*<span id="ticketlimitspan">' + limitReached + '</span>* ' + programInfo +'</button>';
            } else {
                button = '<button type="button" class="' + disabledButtonClass + ' mb-1" disabled>*<span id="ticketlimitspan">Daily Ticket Limit Reached</span>* ' + programInfo +'</button>';
            }
            document.querySelector('#eventinfo')?.appendHtml(button);
        } else if (library < 6) {
            /* It's likely that the reason that there is no capacity in this case is because
            there are only in district tickets left until the general availability window.
            Put up a message that the patron will need to come back later. */
            String? genTicketsOut = globals.noTicketsNowinfo[language];
            String button;
            if (genTicketsOut != null) {
                button = '<button type="button" class="' + disabledButtonClass +' mb-1" disabled>*<span id="genticketsoutspan">' + genTicketsOut + '</span>* ' + programInfo + '</button>';
            } else {
                button = '<button type="button" class="' + disabledButtonClass +' mb-1" disabled>*<span "genticketsoutspan">Only District Cardholder Tickets Remain - Check Back ### Minutes Before Event Start</span>* ' + programInfo + '</button>';
            }
            button = button.replaceAll("###", globals.registrationdelay.toString());
            document.querySelector('#eventinfo')?.appendHtml(button);
        } else {
            /* This will be for a 0 status, meaning that there is no capacity left in a program.
            Again, a disabled button will be shown with that information. */
            String? ticketsOut = globals.ticketsOut[language];
            String button;
            if (ticketsOut != null) {
                button = '<button type="button" class="' + disabledButtonClass +' mb-1" disabled>*<span id="ticketsoutspan">' + ticketsOut + '</span>* ' + programInfo + '</button>';
            } else {
                button = '<button type="button" class="' + disabledButtonClass +' mb-1" disabled>*<span "ticketsoutspan">No Tickets Remaining</span>* ' + programInfo + '</button>';
            }
            document.querySelector('#eventinfo')?.appendHtml(button);
        }
    }
    await Future.delayed(Duration(seconds: reloadDelay));
    window.location.reload();
}

String prettyTime(String unformattedTime) {
    String formattedTime;
    RegExp timere = new RegExp( r"(\d{2}):(\d{2}):\d{2}");
    RegExpMatch? match = timere.firstMatch(unformattedTime);
    if (RegExpMatch != null) {
        String? hourstring = match?.group(1);
        String? minutes = match?.group(2);
        if ((hourstring != null) && (minutes != null)) {
            int hournum = int.parse(hourstring);
            if (hournum > 12) {
                hournum -= 12;
                formattedTime = hournum.toString() + ":" + minutes + " p.m.";
            } else if (hournum == 12) {
                formattedTime = hournum.toString() + ":" + minutes + " p.m.";
            } else {
                formattedTime = hournum.toString() + ":" + minutes + " a.m.";
            }
            return formattedTime;
        } else {
            return "Invalid Time";
        }
    } else {
        return "Invalid Time";
    }
}

//Uses event capacity and ticket count to generate a capacity status number
int capacityCheck(int capacity, int grace, int tickets, int library) {
    if ((capacity + grace - tickets) > 4) {
        //No ticket restrictions at the moment
        //Allow up to 2 adults and 3 children
        int capStatus = library + 9;
        return capStatus;
    } else if ((capacity + grace - tickets) == 4) {
        /* There are fewer than 5 spaces left, but using
        the grace spaces, remaining capacity is at least 4
        Allow getting 3 children and 1 adult tickets.
        To allow for a library value of 0 (i.e. "other")
        add 1 to the library value when turning into a capacity
        status value.  That removes ambiguity between a status of
        0 (no tickets available) and other library. */
        int capStatus = library + 1;
        return capStatus;
    } else {
        //No capacity remaining for this only program.  
        return 0;
    }
}

/*chooseTickets just takes the result of a program selection button and passes that on to
the ticketForm funtion, removing the MouseEvent and adding the multievents value.*/
Future<void> chooseTickets(MouseEvent event, String bchash, String eventid, String eventtime, String eventname, String eventlocation, String eventages, String eventagequal, int capStatus) async {
    if ((bchash != null) && (eventid != null) && (capStatus != null) && (eventtime != null) && (eventname != null) && (eventages != null) && (eventagequal != null)) {
        bool multievents = true;
        ticketForm(capStatus, eventid, eventtime, eventname, eventlocation, eventages, eventagequal, bchash, multievents);
    } else {
        return;
    }
}

//Presents a customized form for selecting tickets
void ticketForm(int capStatus, String eventid, String eventtime, String eventname, String eventlocation, String eventages, String eventagequal, String bchash, bool multievents) {
    String? language = globals.language;
    globals.scanblock?.style.display = "none";
    globals.seblock?.style.display = "none";
    globals.stblock?.style.display = "block";
    
    //Variables for form button function
    if (language == null) {
        language = "english";
    }

    if (capStatus < 9) {
        //Limited Registration - Adult limited to 1
        //Just change the color of the add button and turn on the note.
        document.querySelector('#adultplus')?.attributes['src'] = "images/plusoff150.png";
        document.querySelector('#adultticketsnote')?.style.display = "block";
        document.querySelector('#adultticketsnote')?.text = globals.adultTicketsNote[language];
    }

    /* Turn on the plus and minus buttons.  They always work, but don't do anything unless the 
    conditions are right. */
    document.querySelector('#adultadd')?.onClick.listen((MouseEvent e) => changeTickets(e, "adult", (globals.adultTicketSum + 1).toString(), capStatus));
    document.querySelector('#adultsub')?.onClick.listen((MouseEvent e) => changeTickets(e, "adult", (globals.adultTicketSum - 1).toString(), capStatus));
    document.querySelector('#childadd')?.onClick.listen((MouseEvent e) => changeTickets(e, "child", (globals.youthTicketSum + 1).toString(), capStatus));
    document.querySelector('#childsub')?.onClick.listen((MouseEvent e) => changeTickets(e, "child", (globals.youthTicketSum - 1).toString(), capStatus));

    /* Set hidden form values.  The form isn't actually submitted in the conventional
    way, but it works as a handy place to store these variables until the button is 
    pressed launching the ticket processing function.  It also helps with potential troublshooting. */
    document.querySelector('#capstatusform')?.attributes['value'] = capStatus.toString();
    document.querySelector('#identifierform')?.attributes['value'] = bchash;
    document.querySelector('#eventidform')?.attributes['value'] = eventid;
    document.querySelector('#eventnameform')?.attributes['value'] = eventname;
    document.querySelector('#eventtimeform')?.attributes['value'] = eventtime;
    document.querySelector('#eventlocationform')?.attributes['value'] = eventlocation;

    //Turn on the form submit button
    document.querySelector('#formbutton')?.onClick.listen((MouseEvent e) => sendTicketRequest(e));

    //Fill out the rest of the page: program information and child buttons
    document.querySelector('stheader')?.text = globals.selectTickets[language];
    document.querySelector('#ticketevent')?.text = eventname;
    document.querySelector('#tickettime')?.text = eventtime;
    document.querySelector('#ticketages')?.text = eventages;

    //This has to be added twice on the page and it's a pain, so I'm doing both at the same time
    if (eventagequal == "y") {
        document.querySelector('#ticketagequal')?.classes.add('yearsterm');
        document.querySelector('#cnoteagequal')?.classes.add('yearsterm');
        document.querySelector('#ticketagequal')?.text = globals.yearsTerm[language];
        document.querySelector('#cnoteagequal')?.text = globals.yearsTerm[language];
        bool? contains = document.querySelector('#ticketagequal')?.classes.contains('monthsterm');
        if (contains != null) {
            if (contains) {
                document.querySelector('#ticketagequal')?.classes.remove('monthsterm');
            }
        }
        contains = document.querySelector('#cnoteagequal')?.classes.contains('monthsterm');
        if (contains != null) {
            if (contains) {
                document.querySelector('#cnoteagequal')?.classes.remove('monthsterm');
            }
        }
    } else {
        document.querySelector('#ticketagequal')?.classes.add('monthsterm');
        document.querySelector('#cnoteagequal')?.classes.add('monthsterm');
        document.querySelector('#ticketagequal')?.text = globals.monthsTerm[language];
        document.querySelector('#cnoteagequal')?.text = globals.monthsTerm[language];
        bool? contains = document.querySelector('#ticketagequal')?.classes.contains('yearsterm');
        if (contains != null) {
            if (contains) {
                document.querySelector('#ticketagequal')?.classes.remove('yearsterm');
            }
        }
        contains = document.querySelector('#cnoteagequal')?.classes.contains('yearsterm');
        if (contains != null) {
            if (contains) {
                document.querySelector('#cnoteageqaul')?.classes.remove('yearsterm');
            }
        }
    }
    document.querySelector('#adultticketsheader')?.text = globals.adultTicketsHeader[language];
    document.querySelector('#childticketsheader')?.text = globals.childTicketsHeader[language];
    document.querySelector('#cnotei')?.text = globals.childNoteI[language];
    document.querySelector('#cnoteages')?.text = eventages;
    document.querySelector('#cnoteii')?.text = globals.childNoteII[language];
    document.querySelector('#formbutton')?.text = globals.requestTickets[language];
    document.querySelector('#ticketscancel')?.text = globals.ticketsCancel[language];

    if (multievents == true) {
        //Set the cancel button to return to the events screen
        document.querySelector('#ticketscancel')?.onClick.listen((MouseEvent e) => backToEvents(e));
    } else {
        //Set the cancel button to reset the page
        document.querySelector('#ticketscancel')?.onClick.listen((MouseEvent e) => resetPage(e));
    }
}

void changeTickets(MouseEvent event, String audience, String quantity, int capStatus) {
    if (audience == "adult") {
        if (capStatus > 8) {
            //Don't do anything if the capStatus is in the first tier
            String? currentTotal = document.querySelector('#adultticketsform')?.attributes['value'];
            if (currentTotal != null) {
                if (currentTotal != quantity) {
                    if (quantity == "1") {
                        document.querySelector('#adultminus')?.attributes['src'] = "images/minusoff150.png";
                        document.querySelector('#adultplus')?.attributes['src'] = "images/pluson150.png";
                        document.querySelector('#adulttotal')?.attributes['src'] = "images/one150.png";
                        document.querySelector('#adultticketsform')?.attributes['value'] = "1";
                        globals.adultTicketSum = 1;
                    } else if (quantity == "2") {
                        document.querySelector('#adultminus')?.attributes['src'] = "images/minuson150.png";
                        document.querySelector('#adultplus')?.attributes['src'] = "images/plusoff150.png";
                        document.querySelector('#adulttotal')?.attributes['src'] = "images/two150.png";
                        document.querySelector('#adultticketsform')?.attributes['value'] = "2";
                        globals.adultTicketSum = 2;
                    }
                } //If these values match no need to do anything
            } else {
                //This shouldn't happen, but just set everything to 1
                document.querySelector('#adultticketsform')?.attributes['value'] = "1";
                document.querySelector('#adultminus')?.attributes['src'] = "images/minusoff150.png";
                document.querySelector('#adultplus')?.attributes['src'] = "images/pluson150.png";
                document.querySelector('#adulttotal')?.attributes['src'] = "images/two150.png";
                globals.adultTicketSum = 1;
            }
        } //Don't do anything
    } else {
        //Audience has to be child.  CapStatus really never should come into play here
        String? currentTotal = document.querySelector('#childticketsform')?.attributes['value'];
        if (currentTotal != null) {
            if (currentTotal != quantity) {
                //To change the number of child tickets available, add or remove 
                //else ifs here.
                if (quantity == "1") {
                    document.querySelector('#childminus')?.attributes['src'] = "images/minusoff150.png";
                    document.querySelector('#childplus')?.attributes['src'] = "images/pluson150.png";
                    document.querySelector('#childtotal')?.attributes['src'] = "images/one150.png";
                    document.querySelector('#childticketsform')?.attributes['value'] = "1";
                    globals.youthTicketSum = 1;
                } else if (quantity == "2") {
                    document.querySelector('#childminus')?.attributes['src'] = "images/minuson150.png";
                    document.querySelector('#childplus')?.attributes['src'] = "images/pluson150.png";
                    document.querySelector('#childtotal')?.attributes['src'] = "images/two150.png";
                    document.querySelector('#childticketsform')?.attributes['value'] = "2";
                    globals.youthTicketSum = 2;
                } else if (quantity == "3") {
                    document.querySelector('#childminus')?.attributes['src'] = "images/minuson150.png";
                    document.querySelector('#childplus')?.attributes['src'] = "images/plusoff150.png";
                    document.querySelector('#childtotal')?.attributes['src'] = "images/three150.png";
                    document.querySelector('#childticketsform')?.attributes['value'] = "3";
                    globals.youthTicketSum = 3;
                }
            } //If these values match no need to do anything
        } else {
            //Shouldn't happen, but set to 1 just in case
            document.querySelector('#childticketsform')?.attributes['value'] = "1";
            document.querySelector('#childminus')?.attributes['src'] = "images/minusoff150.png";
            document.querySelector('#childplus')?.attributes['src'] = "images/pluson150.png";
            document.querySelector('#childtotal')?.attributes['src'] = "images/one150.png";
            globals.youthTicketSum = 1;
        }
    }
}

//Turns of the ticket selection screen and turns on the event selection screen
void backToEvents(MouseEvent event) {
    globals.stblock?.style.display = "none";
    globals.seblock?.style.display = "block";
}

/* Send ticket order to ordering script process the response from the script
and print tickets. */
Future<void> sendTicketRequest(MouseEvent event) async {
    String? adultTicketTotal = document.querySelector('#adultticketsform')?.attributes['value'];
    String? childTicketTotal = document.querySelector('#childticketsform')?.attributes['value'];
    String? identifier = document.querySelector('#identifierform')?.attributes['value'];
    String? capStatus = document.querySelector('#capstatusform')?.attributes['value'];
    String? eventid = document.querySelector('#eventidform')?.attributes['value'];
    String? eventName = document.querySelector('#eventnameform')?.attributes['value'];
    String? eventTime = document.querySelector('#eventtimeform')?.attributes['value'];
    String? eventLocation = document.querySelector('#eventlocationform')?.attributes['value'];
    String? language = globals.language;

    if ((adultTicketTotal != null) && (childTicketTotal != null) && (identifier != null) && (capStatus != null) && (eventid != null) && (language != null)) {
        var url = Uri.http(globals.serverurl, globals.orderscript);
        var jsonresponse = await http.post(url, headers: {'Access-Control-Allow-Origin': '*'}, body: {'adult': adultTicketTotal, 'child': childTicketTotal, 'identifier': identifier, 'library': capStatus, 'event': eventid, 'language': language});
        String rawjson = jsonresponse.body;
        try {
            var response = jsonDecode(rawjson);
            if (response['status'] == "success") {
                //The tickets were successfully added.  They need to be printed now

                //Hide the select ticket block
                globals.stblock?.style.display = "none";

                /* These three values haven't been checked and I don't want something wrong
                with them to stop the process at this point, so in the unusual case where they
                can't be successfully retrieved they'll be replaced with filler. */ 
                if (eventName == null) {
                    eventName = "Event";
                }
                if (eventTime == null) {
                    eventTime = "Time";
                }
                if (eventLocation == null) {
                    eventLocation = "Location";
                }

                //Print tickets
                final DateTime now = DateTime.now();
                final DateFormat formatter = DateFormat('MMMM d, y');
                final String today = formatter.format(now);
                final DateFormat datecode = DateFormat('y-M-d-H-m-');
                final String code = datecode.format(now) + identifier.substring(24,32);

                int adultTickets = int.parse(adultTicketTotal);
                int childTickets = int.parse(childTicketTotal);

                //Setup emoji for printing on ticket
                int? emojiseed = int.parse(eventid);
                String emojiid;
                if (emojiseed != null) {
                    //Really only necessary early on, but add some to the seed
                    emojiseed += 100;

                    //There are 33 emoji, so get modulo 33 of the seed
                    emojiseed = emojiseed % 33;

                    //That range is 0-32, so add one
                    emojiseed++;

                    //Derive the image filename from the seed
                    if (emojiseed < 10) {
                        emojiid = "#emoji0" + emojiseed.toString();
                    } else {
                        emojiid = "#emoji" + emojiseed.toString();
                    }
                } else {
                    //Something has gone really wrong here.
                    //Use the default emoji
                    emojiid = "emoji01";
                    print("Failed to identify emoji for event id " + eventid + " because string couldn't be converted to an integer.");
                }

                //Establish element for emoji display
                Element? emojiblock = document.querySelector(emojiid);
                emojiblock?.style.display = "inline";

                int ticketCounter = 1;
                int allTickets = adultTickets + childTickets;
                for (int x = 1; x <= adultTickets; x++) {
                    document.querySelector('#eventprint')?.text = eventName;
                    document.querySelector('#timeprint')?.text = eventTime;
                    document.querySelector('#roomprint')?.text = eventLocation;
                    document.querySelector('#dateprint')?.text = today;
                    document.querySelector('#ageprint')?.text = "1 ADULT";
                    document.querySelector('#countprint')?.text = "Ticket " + ticketCounter.toString() + " of " + allTickets.toString();
                    //Was experiencing problems with occasional double tickets, so the final
                    //printing of "x" in parentheses is for troubleshooting that
                    document.querySelector('#codeprint')?.text = "Order #: " + code + "(" + x.toString() + ")";
                    window.print(); //Should have browser set to print.always_print_silent
                    await Future.delayed(Duration(seconds: 1)); //To slow down printing for troubleshooting
                    ticketCounter++;
                }
                for (int x = 1; x <= childTickets; x++) {
                    document.querySelector('#eventprint')?.text = eventName;
                    document.querySelector('#timeprint')?.text = eventTime;
                    document.querySelector('#roomprint')?.text = eventLocation;
                    document.querySelector('#dateprint')?.text = today;
                    document.querySelector('#ageprint')?.text = "1 CHILD";
                    document.querySelector('#countprint')?.text = "Ticket " + ticketCounter.toString() + " of " + allTickets.toString();
                    document.querySelector('#codeprint')?.text = "Order #: " + code + "(" + x.toString() + ")";
                    window.print(); //Should have browser set to print.always_print_silent
                    await Future.delayed(Duration(seconds: 1));
                    ticketCounter++;            
                }
                /* With the print commands sent, display the printing message.
                If this is done earlier than this point the display command
                overrides the command making sure that it says hidden for printing. */
                globals.finishblock?.style.display = "block";

                /* Wait 5 seconds for the prints to complete and the user to get out of the way
                Then reload the page to restart the process. */
                await Future.delayed(Duration(seconds: 5));
                window.location.reload();         
            } else {
                //There was some kind of error.  Show the error for diagnostics
                String? errorInfo = response['status'];
                if (errorInfo == null) {
                    errorInfo = "Error";
                }
                String? errorDetail = response['detail'];
                if (errorDetail == null) {
                    errorDetail = "The cause of the error is unknown.";
                }
                reportError(errorInfo, errorDetail, "ticketfailure");
            }
        } on FormatException catch (e) {
            reportError(e.toString(), rawjson, "jsonexception");
        } 
    } else {
        String problems = "";
        if (adultTicketTotal == null) {
            problems += "adultTicketTotal is null.";
        }
        if (childTicketTotal == null) {
            problems += "childTicketTotal is null.";
        }
        if (identifier == null) {
            problems += "identifier is null.";
        }
        if (capStatus == null) {
            problems += "capStatus is null.";
        }
        if (eventid == null) {
            problems += "eventid is null.";
        }
        if (language == null) {
            problems += "language is null.";
        }
        reportError("Should have done something", problems, "nullfield");
    }
}

Future<void> reportError(String status, String errorDetail, String tempId, [int? errorDuration]) async {
    /*This is for reporting database errors, which are likely critical
    one way or another.  Shut the kiosk down until an investigation can be made. */
    String language = globals.language;

    globals.scanblock?.style.display = "none";
    globals.seblock?.style.display = "none";
    globals.stblock?.style.display = "none";
    globals.finishblock?.style.display = "none";
    globals.manualblock?.style.display = "none";
    globals.errorblock?.style.display = "block";

    /*If the error duration is set, the ids of the fields will be changed temporarily for 
    language compatibility, and then after the duration in seconds, the page will be 
    reloaded to the default.  If there is no duration set then the error page will be
    displayed indefinitely without language support, presumably because language support
    is not useful and or nearly impossible.*/
    if (errorDuration != null) {

        if (tempId.length > 1) {
            //Probably not necessary to do this but it seems like a good idea
            String? oldheader = globals.errorheader?.id;
            String? oldinfo = globals.errorheader?.id;

            String headerid = tempId + "header";
            String infoid = tempId + "info";

            globals.errorheader?.id = headerid;
            globals.errorinfo?.id = infoid;

            Element? header = document.querySelector(headerid);
            Element? info = document.querySelector(infoid);

            document.querySelector("#" + headerid)?.text = status;
            document.querySelector("#" + infoid)?.text = errorDetail;

//            await Future.delayed(Duration(seconds: errorDuration));

            for (int x = errorDuration; x > 0; x--) {
                document.querySelector("#counter")?.text = x.toString();
                await Future.delayed(Duration(seconds: 1));
            }

            /*Since the page is going to be reloaded anyway this almost
            certainly isn't necessary, but it seems like the right thing to do*/
            if (oldheader != null) {
                document.querySelector(headerid)?.id = oldheader;
            }
            if (oldinfo != null) {
                document.querySelector(infoid)?.id = oldinfo;
            }

            window.location.reload();

        } else {
            reportError("Error","An unexpected error has occurred.","");
        }

    } else {

        document.querySelector('#closedtext')?.text = globals.kioskOffline[language];
        document.querySelector('#errorheader')?.text = status;
        document.querySelector('#errorinfo')?.text = errorDetail;
    }
}