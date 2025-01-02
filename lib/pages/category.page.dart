import 'package:flutter/material.dart';
import 'package:madari_client/features/connections/types/base/base.dart';

import '../utils/grid.dart';

class CategoryPage extends StatelessWidget {
  final LibraryRecord item;

  const CategoryPage({
    super.key,
    required this.item,
    required List filters,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getGridResponsiveColumnCount(context),
        mainAxisSpacing: getGridResponsiveSpacing(context),
        crossAxisSpacing: getGridResponsiveSpacing(context),
        childAspectRatio: 2 / 3,
      ),
      itemBuilder: (ctx, index) {
        return Container();
      },
    );
  }
}
