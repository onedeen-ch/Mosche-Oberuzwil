import 'package:flutter_test/flutter_test.dart';
import 'package:sig_oberuzwil/prayer.dart';
import 'package:timezone/data/latest.dart' as zones;
void main(){
 setUpAll(zones.initializeTimeZones);
 test('valid dates',(){expect(validDate('2026-02-30'),false);expect(validTime('24:00'),false);});
 test('Zurich summer/winter time',(){
 expect(const PrayerTime('2026-01-01','Fajr','05:00','06:00').instant!.timeZoneOffset.inHours,1);
 expect(const PrayerTime('2026-07-01','Fajr','05:00','06:00').instant!.timeZoneOffset.inHours,2);
 });
 test('Iqama separate and next day',(){
 const a=PrayerTime('2026-11-26','Fajr','05:00','06:00');
 const b=PrayerTime('2026-11-27','Fajr','05:00','06:00');
 expect(nextPrayer([a,b],a.instant!.subtract(const Duration(minutes:20))),a);
 expect(nextPrayer([a,b],a.instant!.add(const Duration(minutes:1))),b);
 expect(nextPrayer([],DateTime.now()),isNull);
 });
 test('reject incomplete calendar',()=>expect(()=>parseCalendar('datum;gebet;beginn;moschee\n2026-01-01;Fajr;05:00;06:00'),throwsFormatException));
 test('reject duplicates',()=>expect(()=>parseCalendar('datum;gebet;beginn;moschee\n2026-01-01;Fajr;05:00;06:00\n2026-01-01;Fajr;05:00;06:00'),throwsFormatException));
}
