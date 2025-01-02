
.PHONY: build schema build_web build_mac
build:
	dart run build_runner build --delete-conflicting-outputs

schema:
	dart run drift_dev schema dump lib/database/database.dart drift_schemas/drift_schema_v1.json

build_web:
	flutter build web --target lib/main_web.dart --release --pwa-strategy none --wasm

build_mac:
	flutter build macos --target lib/main.dart --release --no-tree-shake-icons

build_android:
	flutter build apk --release --no-tree-shake-icons

build_windows:
	flutter build windows --release --no-tree-shake-icons
