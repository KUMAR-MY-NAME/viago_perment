import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:packmate/models/wallet.dart';
import 'package:packmate/models/wallet_transaction.dart';
import 'package:packmate/services/wallet_service.dart';
import 'package:packmate/screens/add_money_screen.dart';
import 'package:packmate/screens/withdraw_money_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      return;
    }
    _walletService = WalletService(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 20),
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(child: _buildTransactionList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<Wallet>(
          stream: _walletService.walletStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final wallet = snapshot.data!;
            return Column(
              children: [
                const Text('Current Balance', style: TextStyle(fontSize: 20)),
                Text('₹${wallet.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddMoneyScreen(walletService: _walletService)));
                  },
                  child: const Text('Add Money'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => WithdrawMoneyScreen(walletService: _walletService)));
                  },
                  child: const Text('Withdraw Money'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<List<WalletTransaction>>(
      stream: _walletService.transactionsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions yet.'));
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isDeposit = transaction.type == TransactionType.deposit || transaction.type == TransactionType.refund;
            return Card(
              child: ListTile(
                leading: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: isDeposit ? Colors.green : Colors.red),
                title: Text(transaction.type.toString().split('.').last),
                subtitle: Text('Parcel ID: ${transaction.parcelId ?? 'N/A'}'),
                trailing: Text(
                  '${isDeposit ? '+' : ''}₹${transaction.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(color: isDeposit ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}