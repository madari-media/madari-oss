import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/engine/library.dart';
import 'package:pocketbase/src/dtos/result_list.dart';

import '../../../utils/grid.dart';
import '../component/libray_card.dart';

class LibraryScreen extends StatelessWidget {
  final bool minimal;

  const LibraryScreen({
    super.key,
    this.minimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      leading: null,
      backgroundColor: Colors.black.withOpacity(0.7),
      title: const Text(
        'My Libraries',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLibraryGrid(
    BuildContext context,
    ResultList<LibraryRecord> result,
  ) {
    final count = getGridResponsiveColumnCount(context);

    return SliverPadding(
      padding: EdgeInsets.all(getGridResponsivePadding(context)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count == 3 ? 2 : count,
          mainAxisSpacing: getGridResponsiveSpacing(context),
          crossAxisSpacing: getGridResponsiveSpacing(context),
          childAspectRatio: getGridResponsiveAspectRatio(context),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => LibraryCard(
            library: result.items[index],
          ),
          childCount: result.items.length,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Consumer(builder: (ctx, ref, child) {
      final result = ref.watch(libraryListProvider(1));

      return result.when(
        data: (data) {
          if (data.items.isEmpty) {
            return const Center(
              child: Text("No Libraries Found"),
            );
          }

          return CustomScrollView(
            slivers: [
              if (!isDesktop) _buildAppBar(),
              _buildLibraryGrid(context, result.value!),
            ],
          );
        },
        error: (c, err) {
          return Text("Something went wrong $c");
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    });
  }
}
