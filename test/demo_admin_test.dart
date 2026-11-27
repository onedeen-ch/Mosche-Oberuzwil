import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sig_oberuzwil/demo_admin.dart';
import 'package:sig_oberuzwil/prayer.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUp(()=>SharedPreferences.setMockInitialValues({}));
 test('Local writes require demo session and persist after logout',()async{
  final store=DemoPostStore();
  final post=NewsPost(title:'Test',body:'Nur Testgerät',created:DateTime.now(),pinned:true);
  expect(store.login('wrong'),false);
  await expectLater(store.upsert(post),throwsStateError);
  expect(store.login(DemoPostStore.demoPin),true);
  await store.upsert(post);store.logout();
  expect(store.posts.single.title,'Test');
  final next=DemoPostStore();await next.load();
  expect(next.posts.single.pinned,true);
  await expectLater(next.remove(next.posts.single),throwsStateError);
  next.login(DemoPostStore.demoPin);await next.remove(next.posts.single);
  expect(next.posts,isEmpty);
 });
}
