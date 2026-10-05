import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../provider/discovery_provider.dart';
import 'discovery_chip_row.dart';

class DiscoveryNote extends StatelessWidget {
  const DiscoveryNote({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiscoveryProvider>();

    if (provider.notes == null) {
      return const SizedBox.shrink();
    }

    // Mix all notes from Top + Middle + Base into one list
    final allNotes = <String>{
      ...provider.notes!.top,
      ...provider.notes!.middle,
      ...provider.notes!.base,
    }.toList()..sort(); // optional: keep them alphabetical

    if (allNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return DiscoveryChipRow<String>(
      items: allNotes,
      labelBuilder: (item) => item,
      isSelectedBuilder: (note) => provider.selectedNote == note,
      onSelected: (note) async {
        await context.push(
          Uri(
            path: '/discovery/products',
            queryParameters: {'note': note, 'title': note},
          ).toString(),
        );
      },
    );
  }
}
