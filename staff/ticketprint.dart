import 'dart:html';

//Put here the full path do the management directory
String siteurl = "https://mysite.mysite.com/directory/";

Future<void> main() async {
    String? children = document.querySelector('#children')?.attributes['value'];
    String? adults = document.querySelector('#adults')?.attributes['value'];
    String? allchildren = document.querySelector('#allchildren')?.attributes['value'];
    String? alladults = document.querySelector('#alladults')?.attributes['value'];

    if (children != null) {
        if (adults != null) {
            if (allchildren != null) {
                if (alladults != null) {
                    printall(int.parse(adults), int.parse(children), int.parse(alladults), int.parse(allchildren));
                }
            }
        }
    }
}

Future<void> printall(int adults, int children, int alladults, int allchildren) async {
    int total = alladults + allchildren;
    int printtotal = adults + children;
    int start = total - printtotal + 1;
    int adultcount = adults;

    for (int x = start; x <= total; x++) {
        document.querySelector('#countprint')?.text = "Ticket " + x.toString() + " of " + total.toString();
        if (adultcount != 0) {
            document.querySelector('#ageprint')?.text = "1 ADULT";
            adultcount--;
            window.print();
            await Future.delayed(Duration(seconds: 1));
        } else {
            document.querySelector('#ageprint')?.text = "1 CHILD";
            window.print();
            await Future.delayed(Duration(seconds: 1));
        }
    }
    window.location.assign(siteurl);
}