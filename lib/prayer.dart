import 'package:timezone/timezone.dart' as tz;
const prayers=['Fajr','Dhuhr','Asr','Maghrib','Ischa'];
String dateKey(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
tz.Location get zurich=>tz.getLocation('Europe/Zurich');
tz.TZDateTime nowZurich()=>tz.TZDateTime.now(zurich);
bool validDate(String date){final d=DateTime.tryParse(date);return d!=null&&dateKey(d)==date;}
bool validTime(String s)=>RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s);
class PrayerTime {
 final String date,name,begin,mosque;
 const PrayerTime(this.date,this.name,this.begin,this.mosque);
 tz.TZDateTime? get instant {
  if(!validDate(date)||!validTime(mosque))return null;
  final d=DateTime.parse(date);final t=mosque.split(':');
  return tz.TZDateTime(zurich,d.year,d.month,d.day,int.parse(t[0]),int.parse(t[1]));
 }
}
PrayerTime? nextPrayer(List<PrayerTime> times,DateTime now){
 PrayerTime? next;
 for(final p in times){final t=p.instant;if(t!=null&&!t.isBefore(now)&&(next==null||t.isBefore(next.instant!)))next=p;}
 return next;
}
List<PrayerTime> parseCalendar(String csv){
 final lines=csv.trim().split(RegExp(r'\r?\n'));
 if(lines.first.trim()!='datum;gebet;beginn;moschee')throw const FormatException('Falsche Kopfzeile');
 final seen=<String>{};final days=<String,Set<String>>{};final result=<PrayerTime>[];
 for(final line in lines.skip(1)){
  if(line.trim().isEmpty)continue;
  final p=line.split(';').map((v)=>v.trim()).toList();
  if(p.length!=4||!validDate(p[0])||!prayers.contains(p[1])||!validTime(p[2])||!validTime(p[3])||p[3].compareTo(p[2])<0)throw FormatException('Ungültiger Eintrag: $line');
  if(!seen.add('${p[0]}:${p[1]}'))throw FormatException('Doppelter Eintrag: $line');
  days.putIfAbsent(p[0],()=>{}).add(p[1]);
  result.add(PrayerTime(p[0],p[1],p[2],p[3]));
 }
 if(result.isEmpty||days.values.any((d)=>d.length!=5))throw const FormatException('Fehlende Gebetszeiten');
 final dates=days.keys.toList()..sort();
 for(var i=1;i<dates.length;i++){if(DateTime.parse(dates[i]).difference(DateTime.parse(dates[i-1])).inDays!=1)throw const FormatException('Fehlender Tag');}
 return result;
}
abstract class ContentRepository {
 List<PrayerTime> get calendar;
 List<NewsPost> get posts;
}
class LocalRepository implements ContentRepository {
 @override List<PrayerTime> get calendar=>const [];
 @override List<NewsPost> get posts=>const [];
}
class NewsPost {
 final String title,body,image;final DateTime created;final DateTime? expires;final bool pinned;
 const NewsPost({required this.title,required this.body,required this.created,this.expires,this.pinned=false,this.image=''});
}
List<NewsPost> visiblePosts(List<NewsPost> posts,DateTime now){
 final result=posts.where((p)=>!p.created.isAfter(now)&&(p.expires==null||p.expires!.isAfter(now))).toList();
 result.sort((a,b)=>a.pinned!=b.pinned?(a.pinned?-1:1):b.created.compareTo(a.created));return result;
}
