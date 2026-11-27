import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'prayer.dart';

// Internal UI rehearsal only. Public, non-secret demo PIN; never use for
// production authentication or network writes.
class DemoPostStore {
 static const storageKey='sig_local_demo_posts_v1';
 static const demoPin='2468';
 bool _signedIn=false;
 bool get signedIn=>_signedIn;
 List<NewsPost> _posts=[];
 List<NewsPost> get posts=>List.unmodifiable(_posts);
 bool login(String pin){_signedIn=pin==demoPin;return _signedIn;}
 void logout(){_signedIn=false;}
 void _requireSession(){if(!_signedIn)throw StateError('Nicht angemeldet');}
 Future<void> load()async{
  try{
   final prefs=await SharedPreferences.getInstance();
   final list=jsonDecode(prefs.getString(storageKey)??'[]') as List;
   _posts=list.map((v)=>NewsPost(title:v['title'] as String,body:v['body'] as String,created:DateTime.parse(v['created'] as String),pinned:v['pinned']==true,expires:DateTime.tryParse(v['expires']?.toString()??''))).toList();
  }catch(_){_posts=[];}
 }
 Future<void> _save(List<NewsPost> next)async{
  _requireSession();
  final prefs=await SharedPreferences.getInstance();
  final ok=await prefs.setString(storageKey,jsonEncode(next.map((p)=>{'title':p.title,'body':p.body,'created':p.created.toUtc().toIso8601String(),'pinned':p.pinned,'expires':p.expires?.toUtc().toIso8601String()}).toList()));
  if(!ok)throw StateError('Speichern fehlgeschlagen');
  _posts=next;
 }
 Future<void> upsert(NewsPost post,{NewsPost? previous})async{
  _requireSession();
  if(post.body.trim().isEmpty||post.body.length>5000||post.title.length>120)throw const FormatException('Ungültiger Beitrag');
  final next=List<NewsPost>.of(_posts);
  if(previous==null){if(next.length>=100)throw StateError('Maximal 100 Testbeiträge');next.add(post);}
  else {final i=next.indexOf(previous);if(i<0)throw StateError('Beitrag fehlt');next[i]=post;}
  await _save(next);
 }
 Future<void> remove(NewsPost p)async{_requireSession();await _save(List<NewsPost>.of(_posts)..remove(p));}
}
class DemoAdminPage extends StatefulWidget{
 final DemoPostStore store;
 const DemoAdminPage({super.key,required this.store});
 @override State<DemoAdminPage> createState()=>_DemoAdminPageState();
}
class _DemoAdminPageState extends State<DemoAdminPage>{
 final pin=TextEditingController();
 bool bad=false,busy=false;
 DemoPostStore get store=>widget.store;
 @override void dispose(){store.logout();pin.dispose();super.dispose();}
 void login(){setState((){bad=!store.login(pin.text.trim());pin.clear();});}
 Future<void> edit([NewsPost? post])async{
  final result=await Navigator.push<NewsPost>(context,MaterialPageRoute(builder:(_)=>DemoPostEditor(post:post)));
  if(result==null||!mounted)return;
  await mutate(()=>store.upsert(result,previous:post),'Testbeitrag gespeichert.');
 }
 Future<void> mutate(Future<void> Function() action,String message)async{
  if(busy)return;
  setState(()=>busy=true);
  try{await action();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));}
  catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Änderung fehlgeschlagen. Bitte erneut versuchen.')));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> remove(NewsPost post)async{
  final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Beitrag löschen?'),content:const Text('Der lokale Testbeitrag wird endgültig gelöscht.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Abbrechen')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Löschen'))]));
  if(confirmed==true&&mounted)await mutate(()=>store.remove(post),'Testbeitrag gelöscht.');
 }
 @override Widget build(BuildContext context){
  final primary=Theme.of(context).colorScheme.primary;
  return Scaffold(appBar:AppBar(title:Text(store.signedIn?'Verwaltung':'Admin-Anmeldung'),actions:[if(store.signedIn)IconButton(tooltip:'Abmelden',onPressed:busy?null:()=>setState(store.logout),icon:const Icon(Icons.logout))]),body:SafeArea(child:ListView(padding:const EdgeInsets.all(22),children:[
   Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xffe8f3ed),borderRadius:BorderRadius.circular(12)),child:const Text('Nur Testmodus. Keine echte Anmeldung, kein Firebase. Beiträge bleiben auf diesem Handy.')),
   const SizedBox(height:24),
   if(!store.signedIn)...[
    Icon(Icons.admin_panel_settings_outlined,size:56,color:primary),
    const SizedBox(height:16),
    Text('Admin-Testzugang',style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:8),
    const Text('Geben Sie den Test-PIN ein. Besucher benötigen weiterhin kein Konto.'),
    const SizedBox(height:20),
    TextField(key:const Key('demo-pin'),controller:pin,obscureText:true,keyboardType:TextInputType.number,textInputAction:TextInputAction.done,onSubmitted:(_)=>login(),decoration:InputDecoration(labelText:'Test-PIN',border:const OutlineInputBorder(),errorText:bad?'Test-PIN nicht korrekt':null)),
    const SizedBox(height:16),
    FilledButton(onPressed:login,child:const Text('Anmelden')),
   ]else...[
    Text('Neuigkeiten verwalten',style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:14),
    FilledButton.icon(onPressed:busy?null:()=>edit(),icon:const Icon(Icons.add),label:const Text('Neuer Beitrag')),
    const SizedBox(height:8),
    OutlinedButton.icon(onPressed:busy?null:()=>Navigator.pop(context),icon:const Icon(Icons.home_outlined),label:const Text('Startseite ansehen')),
    const SizedBox(height:22),
    if(store.posts.isEmpty)const Text('Noch keine Testbeiträge.'),
    for(final p in [...store.posts]..sort((a,b)=>b.created.compareTo(a.created)))...[
     Text(p.title.isEmpty?'Beitrag ohne Titel':p.title,style:Theme.of(context).textTheme.titleMedium),
     Text(p.body,maxLines:3,overflow:TextOverflow.ellipsis),
     Text(DateFormat('dd.MM.yyyy HH:mm').format(p.created.toLocal()),style:const TextStyle(fontSize:14)),
     if(p.pinned)const Text('Angeheftet',style:TextStyle(fontWeight:FontWeight.w600)),
     if(p.expires!=null)Text('Sichtbar bis: ${DateFormat('dd.MM.yyyy').format(p.expires!.subtract(const Duration(seconds:1)).toLocal())}',style:const TextStyle(fontSize:14)),
     Wrap(spacing:8,children:[TextButton.icon(onPressed:busy?null:()=>edit(p),icon:const Icon(Icons.edit_outlined),label:const Text('Bearbeiten')),TextButton.icon(onPressed:busy?null:()=>remove(p),icon:const Icon(Icons.delete_outline),label:const Text('Löschen'))]),
     const Divider()
    ],
    const SizedBox(height:20),
    const Text('Push-Mitteilungen werden erst nach der Backend-Einrichtung verfügbar.',style:TextStyle(fontSize:15)),
    const SizedBox(height:12),
    OutlinedButton(onPressed:busy?null:()=>setState(store.logout),child:const Text('Abmelden'))
   ]
  ])));
 }
}
class DemoPostEditor extends StatefulWidget{
 final NewsPost? post;
 const DemoPostEditor({super.key,this.post});
 @override State<DemoPostEditor> createState()=>_DemoPostEditorState();
}
class _DemoPostEditorState extends State<DemoPostEditor>{
 final form=GlobalKey<FormState>();late final TextEditingController title,body;
 late bool pinned;
 DateTime? expires;
 @override void initState(){super.initState();title=TextEditingController(text:widget.post?.title??'');body=TextEditingController(text:widget.post?.body??'');pinned=widget.post?.pinned??false;expires=widget.post?.expires;}
 @override void dispose(){title.dispose();body.dispose();super.dispose();}
 Future<void> selectExpiry()async{
  final now=DateTime.now();final today=DateTime(now.year,now.month,now.day);
  final date=await showDatePicker(context:context,initialDate:today,firstDate:today,lastDate:DateTime(today.year+2,today.month,today.day));
  if(date!=null&&mounted)setState(()=>expires=DateTime(date.year,date.month,date.day+1));
 }
 void save(){
  if(!form.currentState!.validate())return;
  Navigator.pop(context,NewsPost(title:title.text.trim(),body:body.text.trim(),created:widget.post?.created??DateTime.now(),pinned:pinned,expires:expires));
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.post==null?'Neuer Beitrag':'Beitrag bearbeiten')),body:SafeArea(child:Form(key:form,child:ListView(padding:const EdgeInsets.all(22),children:[
  const Text('Dieser Beitrag wird nur auf Ihrem Testgerät angezeigt.',style:TextStyle(fontSize:15)),
  const SizedBox(height:20),
  TextFormField(controller:title,maxLength:120,decoration:const InputDecoration(labelText:'Titel (optional)',border:OutlineInputBorder())),
  const SizedBox(height:12),
  TextFormField(controller:body,minLines:5,maxLines:12,maxLength:5000,decoration:const InputDecoration(labelText:'Beitragstext',alignLabelWithHint:true,border:OutlineInputBorder()),validator:(v)=>v==null||v.trim().isEmpty?'Bitte einen Beitragstext eingeben.':null),
  SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Beitrag anheften'),value:pinned,onChanged:(v)=>setState(()=>pinned=v)),
  ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.event_outlined),title:Text(expires==null?'Ablaufdatum (optional)':'Sichtbar bis ${DateFormat('dd.MM.yyyy').format(expires!.subtract(const Duration(seconds:1)))}'),onTap:selectExpiry,trailing:expires==null?const Icon(Icons.chevron_right):IconButton(tooltip:'Ablaufdatum entfernen',onPressed:()=>setState(()=>expires=null),icon:const Icon(Icons.close))),
  const Divider(),
  const Text('Push-Mitteilungen: in dieser lokalen Testversion nicht verfügbar.',style:TextStyle(fontSize:15)),
  const SizedBox(height:20),
  FilledButton(onPressed:save,child:Text(widget.post==null?'Testbeitrag veröffentlichen':'Änderungen speichern'))
 ]))));
}
