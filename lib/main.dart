import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as zones;
import 'package:url_launcher/url_launcher.dart';
import 'content.dart';
import 'prayer.dart';

const accent=Color(0xff15544a);
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
   colorScheme:ColorScheme.fromSeed(seedColor:accent,surface:Colors.white),
   dividerColor:const Color(0xffdddddd),
   appBarTheme:const AppBarTheme(backgroundColor:Colors.white,surfaceTintColor:Colors.transparent),
   textTheme:const TextTheme(bodyLarge:TextStyle(fontSize:18,height:1.45),bodyMedium:TextStyle(fontSize:18,height:1.45),titleLarge:TextStyle(fontSize:24,fontWeight:FontWeight.w600),titleMedium:TextStyle(fontSize:19,fontWeight:FontWeight.w600)),
   outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(minimumSize:const Size(48,52),foregroundColor:accent,alignment:Alignment.centerLeft,textStyle:const TextStyle(fontSize:17))),
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
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:OutlinedButton(onPressed:()=>openLink(context,url),child:Row(children:[Icon(icon),const SizedBox(width:12),Expanded(child:Text(title))])));
}
List<Widget> contactActions()=>const [
 LinkButton(Icons.call_outlined,S.call,'tel:+41765376152'),
 LinkButton(Icons.mail_outline,S.mail,'mailto:info@sig-oberuzwil.ch')];
class Home extends StatefulWidget{
 const Home({super.key});@override State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home> with WidgetsBindingObserver{
 int tab=0;Timer? timer;final ContentRepository repo=LocalRepository();
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);timer=Timer.periodic(const Duration(seconds:30),(_){if(mounted&&tab==1)setState((){});});}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&mounted)setState((){});}
 @override void dispose(){timer?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override Widget build(BuildContext context){
  final icons=[Icons.home_outlined,Icons.access_time,Icons.info_outline,Icons.person_outline,Icons.volunteer_activism_outlined];
  final pages=[feed,prayerPage,about,membership,donations];
  return Scaffold(
   appBar:AppBar(title:const Text(S.app,style:TextStyle(fontSize:21,fontWeight:FontWeight.w600)),actions:[IconButton(tooltip:'Ansicht aktualisieren',onPressed:()=>setState((){}),icon:const Icon(Icons.refresh))]),
   body:SafeArea(bottom:false,child:Column(children:[
    const Padding(padding:EdgeInsets.fromLTRB(16,6,16,5),child:Text(S.test,style:TextStyle(fontSize:14,color:accent),textAlign:TextAlign.center)),
    const Divider(height:1),
    Expanded(child:ListView(key:PageStorageKey(tab),padding:const EdgeInsets.fromLTRB(18,8,18,28),children:pages[tab]()))
   ])),
   bottomNavigationBar:SafeArea(top:false,child:DecoratedBox(decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:Color(0xffdedede)))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    for(var i=0;i<5;i++) Expanded(child:Semantics(button:true,selected:tab==i,label:S.tabs[i],excludeSemantics:true,child:InkWell(onTap:()=>setState(()=>tab=i),child:ConstrainedBox(constraints:const BoxConstraints(minHeight:64),child:Padding(padding:const EdgeInsets.symmetric(vertical:9,horizontal:2),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icons[i],color:tab==i?accent:Colors.black54),const SizedBox(height:5),Text(S.tabs[i],textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:tab==i?accent:Colors.black87,fontWeight:tab==i?FontWeight.bold:FontWeight.normal))]))))))
   ]))),
  );
 }
 List<Widget> feed(){
  final posts=visiblePosts(repo.posts,nowZurich());
  return [const Heading(S.news),if(posts.isEmpty)const Text(S.noNews),for(final p in posts)PostTile(p),const SizedBox(height:18),const LinkButton(Icons.language,S.websiteNews,website)];
 }
 List<Widget> prayerPage(){
  final now=nowZurich();final date=dateKey(now);final next=nextPrayer(repo.calendar,now);
  final times={for(final t in repo.calendar.where((x)=>x.date==date))t.name:t};
  return [
   Text(DateFormat('EEEE, dd. MMMM yyyy','de_CH').format(now),style:const TextStyle(fontSize:17,color:Colors.black54)),
   const Heading(S.next),
   if(next==null)const Text(S.noTimes)else ...[
    Text(next.name,style:Theme.of(context).textTheme.titleLarge),
    Text(next.mosque,style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold,color:accent)),
    if(next.date!=date)Text(next.date),Text('Gebetsbeginn: ${next.begin}')],
   const Divider(height:32),const Heading(S.prayerToday),
   Table(columnWidths:const {0:FlexColumnWidth(1.2),1:FlexColumnWidth(1),2:FlexColumnWidth(1.1)},defaultVerticalAlignment:TableCellVerticalAlignment.middle,border:const TableBorder(horizontalInside:BorderSide(color:Color(0xffe4e4e4))),children:[
    prayerRow('Gebet','Beginn','Moschee',header:true),
    for(final name in prayers)prayerRow(name,times[name]?.begin??'–',times[name]?.mosque??'–')]),
   if(times.isEmpty)const Padding(padding:EdgeInsets.only(top:12),child:Text(S.noTimes)),
   const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text(S.explanation,style:TextStyle(fontSize:16))),
   const Heading(S.friday),const Text(S.noTimes),const SizedBox(height:14),
   const LinkButton(Icons.calendar_month_outlined,'Offiziellen Gebetskalender öffnen',calendarUrl),
   ...contactActions()];
 }
 TableRow prayerRow(String a,String b,String c,{bool header=false})=>TableRow(children:[for(final entry in [a,b,c].asMap().entries)Padding(padding:const EdgeInsets.symmetric(vertical:14,horizontal:2),child:Text(entry.value,style:TextStyle(fontWeight:header||entry.key==2?FontWeight.bold:FontWeight.normal,fontSize:17)))]);
 List<Widget> about()=>[
  const Heading('Schweizerische Islamische Gemeinschaft Oberuzwil'),const Text(intro),
  const Heading(S.contact),const Text(address),const Text(phone),const Text(email),...contactActions(),
  LinkButton(Icons.map_outlined,S.map,'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address+', Schweiz')}'),
  const LinkButton(Icons.language,S.openWeb,website),
  const Heading(S.hours),const Text('Montag bis Samstag: 05:00–00:00 Uhr\nSonntag: 09:00–22:00 Uhr'),
  const Divider(height:36),const Heading('Vorstand und Team'),const Text('Stand: öffentlich zugängliche Organisationsseite. Die Angaben werden vor der Freigabe bestätigt.',style:TextStyle(fontSize:15)),
  for(final group in team.entries)...[
   Padding(padding:const EdgeInsets.only(top:18,bottom:6),child:Text(group.key,style:Theme.of(context).textTheme.titleMedium)),
   for(final p in group.value)...[
    Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.$1,style:const TextStyle(fontWeight:FontWeight.w600)),Text(p.$2,style:const TextStyle(fontSize:16,color:Colors.black54))])),
    const Divider(height:1)]],
  const SizedBox(height:24),OutlinedButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InfoPage())),child:const Text(S.info)),
  TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminPage())),child:const Text(S.admin))
 ];
 List<Widget> membership()=>[const Heading(S.membership),const Text(S.membershipText),
  for(final title in S.memberDetails)...[Heading(title),const Text(S.missing)],
  const Heading('Kontakt aufnehmen'),...contactActions(),const LinkButton(Icons.language,S.openWeb,website)];
 List<Widget> donations()=>[const Heading(S.donate),const Text(S.donationText),
  const Heading('TWINT'),const Text(S.noQR),
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
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text(S.admin)),body:ListView(padding:const EdgeInsets.all(18),children:const [Heading('Noch nicht eingerichtet'),Text(S.adminDisabled),Heading('Geplant'),Text('Geschützte Anmeldung, Neuigkeiten, Gebetskalender, Team, Mitgliedschaft, Spenden und Push-Mitteilungen.')]));
}
class InfoPage extends StatelessWidget{
 const InfoPage({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('App-Informationen')),body:ListView(padding:const EdgeInsets.all(18),children:const [
  Heading('Datenschutz'),Text('Interne Testversion ohne Benutzerkonto, Standortberechtigung, Werbung, Werbetracking oder Firebase. Die Textinhalte sind lokal enthalten. Externe Links öffnen andere Anwendungen. Die endgültigen Anbieter- und Datenschutzhinweise müssen vor Veröffentlichung freigegeben werden.'),
  Heading('Gemeinschaft'),Text('Schweizerische Islamische Gemeinschaft Oberuzwil'),Text(address),Heading('Version'),Text('0.1.0 – interne Testversion'),
  LinkButton(Icons.language,S.openWeb,website)]));
}
