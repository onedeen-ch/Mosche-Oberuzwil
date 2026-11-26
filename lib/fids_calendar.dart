import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer.dart';

const fidsUrl='https://fids.ch/gebetszeiten/oberuzwil/';
List<PrayerTime> parseFids(String body){
 final doc=html.parse(body);
 for(final table in doc.querySelectorAll('table')){
  final rows=table.querySelectorAll('tr');
  final result=<PrayerTime>[];
  var columns=<int>[];
  for(final row in rows){
   final cells=row.children.where((c)=>c.localName=='td'||c.localName=='th').map((c)=>c.text.trim()).toList();
   final headers=cells.map((c)=>c.toLowerCase()).toList();
   if(headers.contains('fajr')&&headers.contains('dhuhr')&&headers.contains('asr')&&headers.contains('maghrib')&&headers.contains('isha')){
    columns=['fajr','dhuhr','asr','maghrib','isha'].map(headers.indexOf).toList();continue;
   }
   if(columns.length!=5||cells.isEmpty||columns.any((i)=>i>=cells.length))continue;
   final m=RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(cells.first);
   if(m==null)continue;
   final date='${m.group(3)}-${m.group(2)!.padLeft(2,'0')}-${m.group(1)!.padLeft(2,'0')}';
   if(!validDate(date))continue;
   final times=columns.map((i)=>cells[i]).toList();
   if(times.any((t)=>!validTime(t)))continue;
   if(result.any((p)=>p.date==date))throw const FormatException('Doppeltes Datum');
   for(var i=0;i<5;i++){result.add(PrayerTime(date,prayers[i],times[i],''));}
  }
  if(result.isNotEmpty)return result;
 }
 throw const FormatException('Kalender nicht verfügbar');
}
class FidsRepository implements ContentRepository {
 List<PrayerTime> _calendar=[];
 bool offline=false,loading=false;
 DateTime? updated;
 @override List<PrayerTime> get calendar=>List.unmodifiable(_calendar);
 @override List<NewsPost> get posts=>const [];
 Future<void> refresh()async{
  if(loading)return;
  loading=true;
  SharedPreferences? prefs;
  try{
   prefs=await SharedPreferences.getInstance();
   if(_calendar.isEmpty){
    final raw=prefs.getString('fids_oberuzwil_v1');
    if(raw!=null){
     final records=jsonDecode(raw) as List;
     final restored=<PrayerTime>[];
     for(final v in records){
      if(v is! List||v.length!=3)continue;
      final date=v[0].toString(),name=v[1].toString(),begin=v[2].toString();
      if(validDate(date)&&prayers.contains(name)&&validTime(begin))restored.add(PrayerTime(date,name,begin,''));
     }
     _calendar=restored;
     updated=DateTime.tryParse(prefs.getString('fids_updated')??'');
    }
   }
  }catch(_){}
  try{
   final response=await http.get(Uri.parse(fidsUrl)).timeout(const Duration(seconds:12));
   if(response.statusCode!=200)throw const FormatException('Kalender nicht erreichbar');
   final fresh=parseFids(utf8.decode(response.bodyBytes));
   if(!fresh.any((p)=>p.date==dateKey(nowZurich())))throw const FormatException('Heutiges Datum fehlt');
   _calendar=fresh;updated=DateTime.now();offline=false;
   if(prefs!=null){
    await prefs.setString('fids_oberuzwil_v1',jsonEncode(fresh.map((p)=>[p.date,p.name,p.begin]).toList()));
    await prefs.setString('fids_updated',updated!.toIso8601String());
   }
  }catch(_){offline=true;}finally{loading=false;}
 }
}
