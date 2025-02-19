# Open Source Media Manager

An open-source media manager app built with Flutter, designed to stream videos from Stremio addons. This project aims to provide an easy-to-use platform for managing and streaming media content.

## Features
- **Stream Videos** from various Stremio addons.
- **Cross-Platform Support**: Works on Android, iOS supported by Flutter.
- **Open Source**: Contributions are welcome!

## Screenshots

<img alt="Application Screenshot" src="https://downloads.madari.media/madari_app_images/madari_5.jpeg" width="250" title="Home Page">

## Getting Started

### Prerequisites
- Dart SDK and Flutter installed on your machine.
- Ensure you have all necessary dependencies for Flutter projects.

### Local Development
To build and run the project locally, use the following command:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running the App
1. Clone this repository.
2. Navigate to the project directory.
3. Run the app using Flutter's run command:

```bash
flutter run
```

## Contributing
Contributions, issues, and feature requests are welcome!  
Feel free to fork the repository and submit a pull request.

## Legal Disclaimer

This application is designed to be an open source media player that can process URLs and add-ons.

The developers of Madari:

Do not host, develop, or distribute any content
    Do not endorse or promote copyright infringement or illegal activities
    Are not responsible for third-party add-ons or content accessed through them
    Expect users to respect intellectual property rights and their local laws

Users are solely responsible for the add-ons they install and content they access through the application.

## Using Rust Inside Flutter

This project leverages Flutter for GUI and Rust for the backend logic,
utilizing the capabilities of the
[Rinf](https://pub.dev/packages/rinf) framework.

To run and build this app, you need to have
[Flutter SDK](https://docs.flutter.dev/get-started/install)
and [Rust toolchain](https://www.rust-lang.org/tools/install)
installed on your system.
You can check that your system is ready with the commands below.
Note that all the Flutter subcomponents should be installed.

```shell
rustc --version
flutter doctor
```

You also need to have the CLI tool for Rinf ready.

```shell
cargo install rinf
```

Messages sent between Dart and Rust are implemented using Protobuf.
If you have newly cloned the project repository
or made changes to the `.proto` files in the `./messages` directory,
run the following command:

```shell
rinf message
```

Now you can run and build this app just like any other Flutter projects.

```shell
flutter run
```

For detailed instructions on writing Rust and Flutter together,
please refer to Rinf's [documentation](https://rinf.cunarist.com).

