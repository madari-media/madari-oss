import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';

import '../features/connections/service/base_connection_service.dart';
import '../features/connections/types/stremio/stremio_base.types.dart';
import '../features/connections/widget/stremio/stremio_item_viewer.dart';

class StremioItemPage extends StatefulWidget {
  final String type;
  final String id;
  final Meta? meta;
  final String? hero;
  final String connection;
  final String library;

  const StremioItemPage({
    super.key,
    required this.type,
    required this.id,
    required this.connection,
    required this.library,
    this.hero,
    this.meta,
  });

  @override
  State<StremioItemPage> createState() => _StremioItemPageState();
}

class _StremioItemPageState extends State<StremioItemPage> {
  late Query<ConnectionRaw> query = Query(
    key: "item${widget.type}${widget.id}",
    queryFn: () async {
      try {
        final result =
            await BaseConnectionService.connectionByIdRaw(widget.connection);
        final resultFirst = BaseConnectionService.connectionById(result);
        final value = await resultFirst.getItemById(
          Meta(
            type: widget.type,
            id: widget.id,
          ),
        );
        if (value == null) {
          return ConnectionRaw(
            connectionResponse: result,
            item: widget.meta as LibraryItem,
          );
        }

        return ConnectionRaw(
          item: value,
          connectionResponse: result,
        );
      } catch (e, stack) {
        print(e);
        print(stack);
        rethrow;
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      query: query,
      builder: (context, state) {
        Meta? meta;

        if (state.status == QueryStatus.error) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                "Something went wrong ${state.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (state.data?.connectionResponse != null &&
            state.data?.item is Meta) {
          meta = state.data?.item as Meta;
        }

        return StremioItemViewer(
          hero: widget.hero,
          meta: meta ?? widget.meta,
          original: meta,
          library: widget.library,
          service: state.data == null
              ? null
              : BaseConnectionService.connectionById(
                  state.data!.connectionResponse,
                ),
        );
      },
    );
  }
}

class ConnectionRaw {
  ConnectionResponse connectionResponse;
  LibraryItem item;

  ConnectionRaw({
    required this.connectionResponse,
    required this.item,
  });

  toJson() {
    return {
      "connectionResponse": connectionResponse.toJson(),
      "item": item.toJson(),
    };
  }
}
