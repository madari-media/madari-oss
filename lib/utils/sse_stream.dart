import 'package:http/http.dart';

Future<ByteStream> getStream(Request request) async {
  final client = Client();
  StreamedResponse response = await client.send(request);
  return response.stream;
}
