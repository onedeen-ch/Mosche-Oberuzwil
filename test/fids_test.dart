import 'package:flutter_test/flutter_test.dart';
import 'package:sig_oberuzwil/fids_calendar.dart';
import 'package:sig_oberuzwil/prayer.dart';
import 'package:timezone/data/latest.dart' as zones;
void main(){
 setUpAll(zones.initializeTimeZones);
 test('FIDS columns are separate from mosque times',(){
 final rows=parseFids('<table><tr><th></th><th>Fajr</th><th>Shuruq</th><th>Dhuhr</th><th>Asr</th><th>Maghrib</th><th>Isha</th></tr><tr><td>26.11.2026</td><td>05:54</td><td>07:36</td><td>12:16</td><td>14:22</td><td>16:45</td><td>18:15</td></tr></table>');
 expect(rows.length,5);expect(rows.first.date,'2026-11-26');expect(rows[1].begin,'12:16');expect(rows.every((p)=>p.mosque.isEmpty),true);expect(nextPrayer(rows,DateTime.now()),isNull);
 });
 test('Reject unrelated and malformed tables',()=>expect(()=>parseFids('<table><tr><td>unknown</td></tr></table>'),throwsFormatException));
}
