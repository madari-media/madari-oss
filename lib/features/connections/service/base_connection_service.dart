import 'package:flutter/material.dart';
import 'package:madari_client/engine/connection_type.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/connections/service/stremio_connection_service.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../settings/types/connection.dart';
import '../types/base/base.dart';
import '../widget/stremio/stremio_create.dart';

abstract class BaseConnectionService {
  Widget renderCard(LibraryItem item, String heroPrefix);
  Widget renderList(LibraryItem item, String heroPrefix);

  static final Map<String, RecordModel> _item = {};

  final String connectionId;

  static Future<LibraryRecordResponse> getLibraries() async {
    final library =
        await AppEngine.engine.pb.collection("library").getFullList();

    return LibraryRecordResponse(
      data: library
          .map(
            (item) => LibraryRecord.fromRecord(item),
          )
          .toList(),
    );
  }

  factory BaseConnectionService.create(
    Connection item,
    ConnectionTypeRecord type,
  ) {
    switch (type.type) {
      case "stremio_addons":
        return StremioConnectionService(
          connectionId: item.id,
          config: StremioConfig.fromJson(item.config),
        );
    }

    throw ErrorDescription("Connection is not supported");
  }

  static Future<ConnectionResponse> connectionByIdRaw(
    String connectionId,
  ) async {
    RecordModel model_;

    if (_item.containsKey(connectionId)) {
      model_ = _item[connectionId]!;
    } else {
      model_ = await AppEngine.engine.pb
          .collection("connection")
          .getOne(connectionId, expand: "type");
      _item[connectionId] = model_;
    }

    return ConnectionResponse(
      connection: Connection.fromRecord(model_),
      connectionTypeRecord: ConnectionTypeRecord.fromRecord(
        model_.get<RecordModel>("expand.type"),
      ),
    );
  }

  static BaseConnectionService connectionById(
    ConnectionResponse connection,
  ) {
    return BaseConnectionService.create(
      connection.connection,
      connection.connectionTypeRecord,
    );
  }

  static Widget createTypeWidget(String type, OnSuccessCallback onSuccess) {
    switch (type) {
      case "stremio":
        return const StremioCreateConnection();
    }

    throw ErrorDescription("Connection is not supported");
  }

  Future<PaginatedResult<LibraryItem>> getItems(
    LibraryRecord library, {
    List<ConnectionFilterItem>? items,
    int? page,
    int? perPage,
    String? cursor,
  });

  Future<List<LibraryItem>> getBulkItem(
    List<LibraryItem> ids,
  );

  Future<List<ConnectionFilter<T>>> getFilters<T>(
    LibraryRecord library,
  );

  Future<LibraryItem?> getItemById(LibraryItem id);

  Future<void> getStreams(
    LibraryItem id, {
    OnStreamCallback? callback,
  });

  BaseConnectionService({
    required this.connectionId,
  });
}

class StreamList {
  final String title;
  final String? description;
  final DocSource source;
  final StreamSource? streamSource;

  StreamList({
    required this.title,
    this.description,
    required this.source,
    this.streamSource,
  });
}

class StreamSource {
  final String title;
  final String id;

  StreamSource({
    required this.title,
    required this.id,
  });
}

class ConnectionResponse {
  final Connection connection;
  final ConnectionTypeRecord connectionTypeRecord;

  ConnectionResponse({
    required this.connectionTypeRecord,
    required this.connection,
  });

  Map<String, dynamic> toJson() {
    return {
      "connection": connection,
      "connectionTypeRecord": connectionTypeRecord,
    };
  }
}

typedef OnSuccessCallback = void Function(String connectionId);

class LibraryRecordResponse extends Jsonable {
  final List<LibraryRecord> data;

  LibraryRecordResponse({
    required this.data,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "data": data.map((item) => item.toJson()).toList(),
    };
  }
}

class ConnectionFilter<T> {
  final String title;
  final ConnectionFilterType type;
  final List<T>? values;

  ConnectionFilter({
    required this.title,
    required this.type,
    this.values,
  });
}

enum ConnectionFilterType {
  text,
  options,
}

class ConnectionFilterItem {
  final String title;
  final dynamic value;

  ConnectionFilterItem({
    required this.title,
    required this.value,
  });
}

abstract class LibraryItem extends Jsonable {
  late final String id;

  LibraryItem({
    required this.id,
  });

  @override
  Map<String, dynamic> toJson();
}

abstract class PaginatedResult<T extends LibraryItem> {
  List<T> get items;
  bool get hasMore;

  Map<String, dynamic> toJson() {
    return {
      "items": items.map((res) => res.toJson()),
      "hasMore": hasMore,
    };
  }
}

class CursorPaginatedResult<T extends LibraryItem>
    implements PaginatedResult<T> {
  @override
  final List<T> items;
  @override
  final bool hasMore;
  final String? nextCursor;

  CursorPaginatedResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  Map<String, dynamic> toJson() {
    return {
      "items": items.map((res) => res.toJson()),
      "hasMore": hasMore,
      "nextCursor": nextCursor,
    };
  }
}

class PagePaginatedResult implements PaginatedResult {
  @override
  final List<LibraryItem> items;
  @override
  final bool hasMore;
  final int totalPages;
  final int currentPage;

  PagePaginatedResult({
    required this.items,
    required this.hasMore,
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "items": items.map((res) => res.toJson()).toList(),
      "hasMore": hasMore,
      "totalPages": totalPages,
      "currentPage": currentPage,
    };
  }
}
