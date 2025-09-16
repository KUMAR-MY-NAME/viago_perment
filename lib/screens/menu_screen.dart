import 'package:flutter/material.dart';
import 'cancellation_refund_screen.dart';
import 'support_screen.dart';
import 'help_screen.dart';
import 'wallet_screen.dart';
import 'blocked_users_screen.dart';
import 'my_reports_screen.dart';

class MenuScreen extends StatelessWidget {
  final String? username;
  const MenuScreen({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Text(
              "Hello, ${username ?? 'User'}",
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text("Cancellation & Refund"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CancellationRefundScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text("Support"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text("Wallet"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WalletScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text("Blocked Users"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BlockedUsersScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text("My Reports"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyReportsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
