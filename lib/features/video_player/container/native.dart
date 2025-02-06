export 'set_delay_stub.dart'
    if (dart.library.html) 'set_delay_web.dart'
    if (dart.library.io) 'set_delay_native.dart';
