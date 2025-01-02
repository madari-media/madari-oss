import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';

Future<ByteStream> getStream(Request request) async {
  final FetchClient fetchClient = FetchClient(mode: RequestMode.cors);
  final FetchResponse response = await fetchClient.send(request);
  return response.stream;
}
