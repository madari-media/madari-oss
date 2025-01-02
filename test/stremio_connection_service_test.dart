import 'package:flutter_test/flutter_test.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/connections/service/stremio_connection_service.dart';

void main() {
  test("StremioConnectionService tests", () async {
    final connection = StremioConnectionService(
      connectionId: "",
      config: StremioConfig(addons: []),
    );

    final library = LibraryRecord(
      id: "id",
      icon: 'icon',
      title: "title",
      types: ['videos'],
      config: [
        "{\"type\":\"movie\",\"id\":\"top\",\"title\":\"Top Movies\",\"addon\":\"https://v3-cinemeta.strem.io/manifest.json\",\"item\":{\"type\":\"movie\",\"id\":\"top\",\"name\":\"Last videos\"}}"
      ],
      connection: "abc",
      connectionType: "stremio_addons",
    );

    final filters = await connection.getFilters(library);

    print(filters);

    final records = await connection.getItems(
      library,
      page: 2,
      items: [
        ConnectionFilterItem(
          title: "search",
          value: "matrix",
        ),
      ],
    );

    print(records);
  });
}
