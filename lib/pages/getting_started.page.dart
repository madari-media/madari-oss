import 'package:flutter/material.dart';
import 'package:madari_client/features/getting_started/container/getting_started.dart';

class GettingStartedPage extends StatelessWidget {
  static String get routeName {
    return "/getting-started";
  }

  const GettingStartedPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GettingStartedScreen(
      onCallback: () {},
    );
  }
}
