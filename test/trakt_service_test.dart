import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';

void main() {
  testWidgets('Test trakt integration', (WidgetTester tester) async {
    final service = TraktService();

    await DotEnv().load(isOptional: true);
  });
}
