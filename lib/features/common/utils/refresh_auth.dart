import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';

Future<void> refreshAuth() async {
  final pb = AppPocketBaseService.instance.pb;
  final userCollection = pb.collection("users");

  final user = await userCollection.getOne(
    pb.authStore.record!.id,
  );
  pb.authStore.save(pb.authStore.token, user);
}
