import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'transactions_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [DashboardPage(), TransactionsPage()];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // se estiver na aba 1 (Transações), volta para 0 (Dashboard)
    if (_index != 0) {
      setState(() => _index = 0);
      _controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return false; // cancela o pop (não sai do app)
    }
    return true; // permite sair/minimizar
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // PageView dá o slide horizontal entre as abas
        body: PageView(
          controller: _controller,
          physics:
              const NeverScrollableScrollPhysics(), // troca só via bottom bar
          onPageChanged: (i) => setState(() => _index = i),
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) {
            setState(() => _index = i);
            _controller.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Transações',
            ),
          ],
        ),
      ),
    );
  }
}
