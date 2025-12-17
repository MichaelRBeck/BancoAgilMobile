import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  String _saudacao() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final color = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    if (user == null) {
      return Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_saudacao()}!',
            style: TextStyle(
              color: onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final docStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: docStream,
      builder: (context, snap) {
        String name = '';
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>?;
          name = (data?['fullName'] ?? '').toString().trim();
        }
        final firstName = name.isEmpty ? '' : name.split(' ').first;

        return Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName.isEmpty
                            ? '${_saudacao()}!'
                            : '${_saudacao()}, $firstName',
                        style: TextStyle(
                          color: onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toBeginningOfSentenceCase(
                          DateFormat(
                            'MMMM \'de\' y',
                            'pt_BR',
                          ).format(DateTime.now()),
                        )!,
                        style: TextStyle(
                          // ignore: deprecated_member_use
                          color: onPrimary.withOpacity(.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
