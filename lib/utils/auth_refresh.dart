import '../engine/engine.dart';

Future<void> refreshAuth() async {
  final pb = AppEngine.engine.pb;
  final userCollection = pb.collection("users");

  final user = await userCollection.getOne(
    AppEngine.engine.pb.authStore.record!.id,
  );
  pb.authStore.save(pb.authStore.token, user);
}
