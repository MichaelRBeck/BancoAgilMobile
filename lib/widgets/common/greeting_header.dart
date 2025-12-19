import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/user/presentation/providers/user_provider.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    final name = user?.fullName.split(' ').first ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá${name.isNotEmpty ? ', $name' : ''} 👋',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Bem-vindo de volta',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
