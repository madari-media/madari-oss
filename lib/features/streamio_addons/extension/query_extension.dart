import 'package:cached_query_flutter/cached_query_flutter.dart';

extension QueryExtension<T> on Query<T> {
  Future<T> queryFn() async {
    final result = await stream
        .where((state) => state.status != QueryStatus.loading)
        .first;

    if (result.error != null) {
      throw result.error!;
    }

    return result.data!;
  }
}
