import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_client/features/streamio_addons/service/stremio_addon_service.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/widgets/error_card.dart';

import '../../streamio_addons/models/stremio_base_types.dart';
import '../containers/explore_addon.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late Query<List<StremioManifest>> _query;

  @override
  void initState() {
    super.initState();

    setQuery();
  }

  void setQuery() {
    _query = Query(
      key: "addons",
      queryFn: () async {
        final result = StremioAddonService.instance;

        return await result
            .getInstalledAddons(
              enabledOnly: true,
            )
            .queryFn();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.explore_outlined),
        title: const Text("Explore"),
      ),
      body: QueryBuilder(
        builder: (context, state) {
          if (state.status == QueryStatus.loading || state.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.data?.isEmpty == true) {
            return const ErrorCard(
              error: "No Addons found",
              title: "No addons are configured",
            );
          }

          return ExploreAddon(
            data: state.data!,
          );
        },
        query: _query,
      ),
    );
  }
}
