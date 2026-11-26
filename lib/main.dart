import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:url_launcher/url_launcher.dart';
import 'content.dart';
import 'prayer.dart';
import 'fids_calendar.dart';

const accent=Color(0xff07513b);
const paleGreen=Color(0xffe8f3ed);
const greenBorder=Color(0xffc8ded2);
const ink=Color(0xff192420);
Future<void> main()async{
 WidgetsFlutterBinding.ensureInitialized();
 zones.initializeTimeZones();await initializeDateFormatting('de_CH');
 runApp(const SigApp());
}
class SigApp extends StatelessWidget {
 const SigApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(
  title:S.app,debugShowCheckedModeBanner:false,locale:const Locale('de','CH'),
  supportedLocales:const [Locale('de','CH'),Locale('de')],
  localizationsDelegates:GlobalMaterialLocalizations.delegates,
  theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:Colors.white,
   colorScheme:ColorScheme.fromSeed(seedColor:accent,surface:Colors.white).copyWith(primary:accent,onPrimary:Colors.white,onSurface:ink),
   dividerColor:const Color(0xffdddddd),
   appBarTheme:const AppBarTheme(backgroundColor:accent,surfaceTintColor:Colors.transparent,foregroundColor:Colors.white,elevation:0,systemOverlayStyle:SystemUiOverlayStyle.light),
   textTheme:const TextTheme(bodyLarge:TextStyle(fontSize:18,height:1.45),bodyMedium:TextStyle(fontSize:18,height:1.45),titleLarge:TextStyle(fontSize:24,fontWeight:FontWeight.w700,color:ink),titleMedium:TextStyle(fontSize:19,fontWeight:FontWeight.w600,color:ink)),
   outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(minimumSize:const Size(48,52),foregroundColor:accent,backgroundColor:paleGreen,side:const BorderSide(color:greenBorder),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),alignment:Alignment.centerLeft,textStyle:const TextStyle(fontSize:17,fontWeight:FontWeight.w600))),
   filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(minimumSize:const Size(48,52),backgroundColor:accent,textStyle:const TextStyle(fontSize:17)))),
  home:const Home());
}
Future<void> openLink(BuildContext context,String link)async{
 try{final uri=Uri.parse(link);if(!['https','tel','mailto'].contains(uri.scheme)||!await launchUrl(uri,mode:LaunchMode.externalApplication))throw Exception();}
 catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text(S.linkError)));}
}
class Heading extends StatelessWidget {
 final String text;const Heading(this.text,{super.key});
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:20,bottom:10),child:Semantics(header:true,child:Text(text,style:Theme.of(context).textTheme.titleLarge)));
}
class LinkButton extends StatelessWidget{
 final IconData icon;final String title,url;const LinkButton(this.icon,this.title,this.url,{super.key});
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:OutlinedButton(onPressed:()=>openLink(context,url),child:Row(children:[Icon(icon),const SizedBox(width:12),Expanded(child:Text(title)),const Icon(Icons.chevron_right,size:20)])));
}
List<Widget> contactActions()=>const [
 LinkButton(Icons.call_outlined,S.call,'tel:+41765376152'),
 LinkButton(Icons.mail_outline,S.mail,'mailto:info@sig-oberuzwil.ch')];
class Home extends StatefulWidget{
 const Home({super.key});@override State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home> with WidgetsBindingObserver{
 int tab=0;Timer? timer;final FidsRepository repo=FidsRepository();
 String? requestedDay;
 Future<void> refresh({bool force=false}) async {
  final day=dateKey(nowZurich());
  if(!force&&requestedDay==day)return;
  requestedDay=day;
  if(mounted)setState((){});
  await repo.refresh();
  if(mounted)setState((){});
 }
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);timer=Timer.periodic(const Duration(seconds:30),(_){if(mounted){refresh();if(tab==1)setState((){});}});WidgetsBinding.instance.addPostFrameCallback((_)=>refresh());}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&mounted){setState((){});refresh();}}
 @override void dispose(){timer?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override Widget build(BuildContext context){
  final icons=[Icons.home_outlined,Icons.nights_stay_outlined,Icons.info_outline,Icons.group_outlined,Icons.favorite_border];
  final pages=[feed,prayerPage,about,membership,donations];
  return Scaffold(
   appBar:AppBar(toolbarHeight:64,title:const Text(S.app,style:TextStyle(fontSize:22,fontWeight:FontWeight.w700)),actions:[IconButton(tooltip:'Ansicht aktualisieren',onPressed:()=>refresh(force:true),icon:const Icon(Icons.refresh)),const SizedBox(width:8)]),
   body:SafeArea(bottom:false,child:Column(children:[
    const ColoredBox(color:paleGreen,child:Padding(padding:EdgeInsets.symmetric(horizontal:20,vertical:10),child:Row(children:[Icon(Icons.info_outline,size:16,color:accent),SizedBox(width:8),Expanded(child:Text(S.test,style:TextStyle(fontSize:13,color:accent)))]))),
    const Divider(height:1),
    Expanded(child:ListView(key:PageStorageKey(tab),padding:const EdgeInsets.fromLTRB(22,16,22,36),children:pages[tab]()))
   ])),
   bottomNavigationBar:ColoredBox(color:Colors.white,child:SafeArea(top:false,child:DecoratedBox(
    decoration:const BoxDecoration(border:Border(top:BorderSide(color:greenBorder))),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
     for(var i=0;i<5;i++)Expanded(child:Semantics(button:true,selected:tab==i,label:S.tabs[i],excludeSemantics:true,child:InkWell(onTap:()=>setState(()=>tab=i),child:Padding(
      padding:const EdgeInsets.fromLTRB(2,9,2,10),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
       Container(width:48,height:34,decoration:BoxDecoration(color:tab==i?paleGreen:Colors.transparent,borderRadius:BorderRadius.circular(18)),child:Icon(icons[i],size:24,color:tab==i?accent:Colors.black54)),
       const SizedBox(height:4),
       Text(S.tabs[i],textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:tab==i?accent:ink,fontWeight:tab==i?FontWeight.w700:FontWeight.normal))
      ])
     ))))
    ])
   ))),
  );
 }
 List<Widget> feed(){
  final posts=visiblePosts(repo.posts,nowZurich());
  return [
   const Heading(S.news),
   if(posts.isEmpty)...[
    const SizedBox(height:12),
    Container(padding:const EdgeInsets.all(26),decoration:BoxDecoration(color:paleGreen,borderRadius:BorderRadius.circular(18)),child:const Column(children:[
     CircleAvatar(radius:30,backgroundColor:Colors.white,child:Icon(Icons.article_outlined,color:accent,size:30)),
     SizedBox(height:18),Text('Noch keine Neuigkeiten',style:TextStyle(fontSize:21,fontWeight:FontWeight.w700,color:accent),textAlign:TextAlign.center),
     SizedBox(height:8),Text('Neue Mitteilungen der Gemeinde erscheinen hier.',textAlign:TextAlign.center)
    ])),
    const SizedBox(height:24)
   ],
   for(final p in posts)PostTile(p),const LinkButton(Icons.language,S.websiteNews,website)
  ];
 }
 List<Widget> prayerPage(){
  final now=nowZurich();final date=dateKey(now);final next=nextPrayer(repo.calendar,now);
  final times={for(final t in repo.calendar.where((x)=>x.date==date))t.name:t};
  return [
   Text(DateFormat('EEEE, dd. MMMM yyyy','de_CH').format(now),style:const TextStyle(fontSize:17,color:Colors.black54)),
   const SizedBox(height:18),
   Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:24),decoration:BoxDecoration(color:accent,borderRadius:BorderRadius.circular(18)),child:Column(children:[
    const Text(S.next,textAlign:TextAlign.center,style:TextStyle(fontSize:17,color:Colors.white,fontWeight:FontWeight.w600)),
    const SizedBox(height:14),
    if(next==null)...[
     const Text('–:–',style:TextStyle(fontSize:46,fontWeight:FontWeight.w700,color:Colors.white)),
     const Text('Moscheezeit noch nicht veröffentlicht',textAlign:TextAlign.center,style:TextStyle(fontSize:16,color:Colors.white))
    ]else...[
     Text(next.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w600,color:Colors.white)),
     Text(next.mosque,style:const TextStyle(fontSize:46,fontWeight:FontWeight.w700,color:Colors.white)),
     if(next.date!=date)Text(next.date,style:const TextStyle(color:Colors.white)),
     Text('Gebetsbeginn: ${next.begin}',style:const TextStyle(fontSize:16,color:Colors.white))
    ]
   ])),
   const SizedBox(height:24),
   ClipRRect(borderRadius:BorderRadius.circular(12),child:Table(columnWidths:const {0:FlexColumnWidth(1.2),1:FlexColumnWidth(1),2:FlexColumnWidth(1.1)},defaultVerticalAlignment:TableCellVerticalAlignment.middle,border:const TableBorder(horizontalInside:BorderSide(color:greenBorder)),children:[
    prayerRow('Gebet','Beginn','Moschee',header:true),
    for(final name in prayers)prayerRow(name,times[name]?.begin??'–',(times[name]?.mosque.isNotEmpty??false)?times[name]!.mosque:'–')])),
   if(repo.loading)const Padding(padding:EdgeInsets.only(top:12),child:LinearProgressIndicator()),
   if(!repo.loading&&times.isEmpty)const Padding(padding:EdgeInsets.only(top:12),child:Text(S.noTimes)),
   if(repo.offline)Padding(padding:const EdgeInsets.only(top:12),child:Text(repo.updated==null?'Kalender momentan nicht erreichbar.':'Kalender aus Cache – zuletzt aktualisiert ${DateFormat('dd.MM.yyyy HH:mm').format(repo.updated!.toLocal())}',style:const TextStyle(fontSize:14))),
   if(repo.offline)TextButton(onPressed:()=>refresh(force:true),child:const Text('Erneut versuchen')),
   const Padding(padding:EdgeInsets.only(top:12),child:Text('Gebetsbeginn: FIDS-Kalender für Oberuzwil. Moscheezeiten werden separat veröffentlicht.',style:TextStyle(fontSize:14,color:Colors.black54))),
   const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text(S.explanation,style:TextStyle(fontSize:16))),
   const Heading(S.friday),const Text(S.noTimes),const SizedBox(height:14),
   const LinkButton(Icons.calendar_month_outlined,'Gebetskalender der Moschee',calendarUrl),
   const LinkButton(Icons.language,'Quelle: FIDS Oberuzwil',fidsUrl)];
 }
 TableRow prayerRow(String a,String b,String c,{bool header=false})=>TableRow(decoration:BoxDecoration(color:header?paleGreen:Colors.white),children:[for(final entry in [a,b,c].asMap().entries)Padding(padding:const EdgeInsets.symmetric(vertical:14,horizontal:5),child:Text(entry.value,textAlign:entry.key==0?TextAlign.start:TextAlign.center,style:TextStyle(fontWeight:header||entry.key==2?FontWeight.bold:FontWeight.normal,fontSize:16,color:header||entry.key==2?accent:ink)))]);
 List<Widget> about()=>[
  Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:paleGreen,borderRadius:BorderRadius.circular(16)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Schweizerische Islamische Gemeinschaft Oberuzwil',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:accent)),SizedBox(height:10),Text(intro)])),
  const Heading(S.contact),const Text(address),const Text(phone),const Text(email),...contactActions(),
  LinkButton(Icons.map_outlined,S.map,'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address+', Schweiz')}'),
  const LinkButton(Icons.language,S.openWeb,website),
  const Heading(S.hours),const Text('Montag bis Samstag: 05:00–00:00 Uhr\nSonntag: 09:00–22:00 Uhr'),
  const Divider(height:36),
  SectionLink(Icons.groups_outlined,'Vorstand und Team',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TeamPage()))),
  const SizedBox(height:24),OutlinedButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InfoPage())),child:const Text(S.info)),
  TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPage())),child:const Text(S.admin))
 ];
 List<Widget> membership()=>[const Heading(S.membership),Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:paleGreen,borderRadius:BorderRadius.circular(16)),child:const Text(S.membershipText)),
  for(final title in S.memberDetails)...[Padding(padding:const EdgeInsets.only(top:16),child:Text(title,style:const TextStyle(fontWeight:FontWeight.w600))),const Text(S.missing,style:TextStyle(color:Colors.black54,fontSize:16)),const Divider(height:24)],
  const Heading('Kontakt aufnehmen'),...contactActions(),const LinkButton(Icons.language,S.openWeb,website)];
 List<Widget> donations()=>[const Heading(S.donate),const Text(S.donationText),
  const SizedBox(height:24),Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:paleGreen,borderRadius:BorderRadius.circular(16)),child:const Column(children:[Text('TWINT',style:TextStyle(fontSize:22,fontWeight:FontWeight.w600,color:accent)),SizedBox(height:22),Icon(Icons.qr_code_scanner,size:76,color:accent),SizedBox(height:16),Text('Platzhalter – nicht zahlbar',style:TextStyle(fontWeight:FontWeight.bold),textAlign:TextAlign.center),SizedBox(height:8),Text(S.noQR,textAlign:TextAlign.center)])),
  const Heading('Banküberweisung'),const Text(S.noBank),
  const Divider(height:32),const Heading('Fragen zu Spenden'),...contactActions()];
}
class PostTile extends StatefulWidget {
 final NewsPost post;const PostTile(this.post,{super.key});@override State<PostTile> createState()=>_PostTileState();
}
class _PostTileState extends State<PostTile>{
 bool expanded=false;
 @override Widget build(BuildContext context){
 final p=widget.post;final links=RegExp(r'https?://[^\s]+').allMatches(p.body).map((m)=>m.group(0)!).toSet();
 return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  if(p.pinned)const Text('Angeheftet',style:TextStyle(color:accent,fontSize:15)),
  Row(children:[Image.network(logoUrl,height:40,width:40,errorBuilder:(_,__,___)=>const SizedBox(width:40)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text(S.app,style:TextStyle(fontWeight:FontWeight.bold)),Text(DateFormat('dd.MM.yyyy HH:mm').format(p.created.toLocal()),style:const TextStyle(fontSize:14))]))]),
  if(p.title.isNotEmpty)Heading(p.title),Text(!expanded&&p.body.length>350?'${p.body.substring(0,350)}…':p.body),
  if(p.body.length>350)TextButton(onPressed:()=>setState(()=>expanded=!expanded),child:Text(expanded?'Weniger anzeigen':'Mehr anzeigen')),
  for(final link in links)LinkButton(Icons.link,'Link öffnen',link),
  if(p.image.isNotEmpty)Semantics(button:true,label:'Bild vergrössern',child:InkWell(onTap:()=>showDialog(context:context,builder:(ctx)=>Dialog(child:Column(mainAxisSize:MainAxisSize.min,children:[Flexible(child:InteractiveViewer(child:Image.network(p.image,errorBuilder:(_,__,___)=>const Text('Bild nicht verfügbar')))),TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Schliessen'))]))),child:Image.network(p.image,errorBuilder:(_,__,___)=>const Text('Bild nicht verfügbar')))),
  const Divider(height:32)]);
 }
}
class AdminPage extends StatelessWidget{
 const AdminPage({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text(S.admin)),body:ListView(padding:const EdgeInsets.all(18),children:const [Heading('Noch nicht eingerichtet'),Text(S.adminDisabled),Heading('Geplant'),Text('Nur vorab berechtigte Administratoren erhalten eine Anmeldung. Besucher benötigen kein Konto. Der Vorstand pflegt die Moscheezeiten unabhängig vom FIDS-Gebetsbeginn. Push-Mitteilungen ausschliesslich für Neuigkeiten nach Zustimmung; keine Gebetserinnerungen.')]));
}
class InfoPage extends StatelessWidget{
 const InfoPage({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('App-Informationen')),body:ListView(padding:const EdgeInsets.all(18),children:const [
  Heading('Datenschutz'),Text('Interne Testversion ohne Benutzerkonto, Standortberechtigung, Werbung, Werbetracking oder Firebase. Die Gemeindeinformationen sind lokal enthalten. Die App lädt den öffentlichen FIDS-Gebetskalender ausschliesslich für Oberuzwil über das Internet. Dabei wird die übliche IP-Adresse an den Anbieter übertragen. Externe Links öffnen andere Anwendungen. Die endgültigen Anbieter- und Datenschutzhinweise müssen vor Veröffentlichung freigegeben werden.'),
  Heading('Gemeinschaft'),Text('Schweizerische Islamische Gemeinschaft Oberuzwil'),Text(address),Heading('Version'),Text('0.3.0 – interne Testversion'),
  LinkButton(Icons.language,S.openWeb,website)]));
}

class SectionLink extends StatelessWidget {
 final IconData icon; final String text; final VoidCallback action;
 const SectionLink(this.icon,this.text,this.action,{super.key});
 @override Widget build(BuildContext context)=>ListTile(contentPadding:const EdgeInsets.symmetric(vertical:5),leading:Icon(icon,color:accent),title:Text(text,style:const TextStyle(fontWeight:FontWeight.w600)),trailing:const Icon(Icons.chevron_right,color:accent),onTap:action);
}
class TeamPage extends StatelessWidget {
 const TeamPage({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Vorstand und Team')),body:ListView(padding:const EdgeInsets.all(22),children:[
 const Text('Die veröffentlichten Funktionen werden vor Freigabe durch den Vorstand bestätigt.',style:TextStyle(fontSize:15,color:Colors.black54)),
 for(final group in team.entries)...[Heading(group.key),for(final p in group.value)...[
 ListTile(contentPadding:const EdgeInsets.symmetric(vertical:4),leading:const CircleAvatar(backgroundColor:Color(0xffeff5f1),child:Icon(Icons.person_outline,color:accent)),title:Text(p.$1,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text(p.$2)),const Divider(height:1)]]]));
}
