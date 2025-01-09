.PHONY: build schema build_web build_mac build_android build_windows build_ipa build_linux build_android_tv

BUILD_ID := $(or $(GITHUB_RUN_ID),dev)

build:
	dart run build_runner build --delete-conflicting-outputs

schema:
	dart run drift_dev schema dump lib/database/database.dart drift_schemas/drift_schema_v1.json

build_web:
	flutter build web --target lib/main_web.dart --release --pwa-strategy none --wasm --dart-define=BUILD_ID=$(BUILD_ID)

build_mac:
	flutter build macos --target lib/main.dart --release --dart-define=BUILD_ID=$(BUILD_ID)

build_android:
	flutter build apk --release --dart-define=BUILD_ID=$(BUILD_ID)

build_android_tv:
	flutter build apk --release --dart-define=BUILD_ID=$(BUILD_ID) --dart-define=IS_TV=true

build_windows:
	flutter build windows --release --dart-define=BUILD_ID=$(BUILD_ID)

build_ipa:
	flutter build ios --release --no-codesign --dart-define=BUILD_ID=$(BUILD_ID)

build_linux:
	flutter build linux --release --dart-define=BUILD_ID=$(BUILD_ID)
