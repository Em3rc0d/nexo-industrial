import 'package:flutter/material.dart';

import '../activity/activity_screen.dart';
import '../activity/activity_store.dart';
import '../companies/companies_screen.dart';
import '../companies/domain/company.dart';
import '../map/map_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.companies,
    required this.activityStore,
  });

  final List<Company> companies;
  final ActivityStore activityStore;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CompaniesScreen(
        companies: widget.companies,
        activityStore: widget.activityStore,
      ),
      MapScreen(
        companies: widget.companies,
        activityStore: widget.activityStore,
      ),
      ActivityScreen(activityStore: widget.activityStore),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_index == 1)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '© OpenStreetMap contributors · openstreetmap.org/copyright',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment),
                label: 'Cuentas',
              ),
              NavigationDestination(
                icon: Icon(Icons.location_on_outlined),
                selectedIcon: Icon(Icons.location_on),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Actividad',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
