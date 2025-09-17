import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'available_items_screen.dart';
import 'rental_batch_screen.dart';
import 'rental_screen.dart';
import 'bill_generation_screen.dart';
import 'rental_report_screen.dart';
import 'stock_management_screen.dart';

// Entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Root Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rental App',
      home: const MainNavigationScreen(), // <- Use a custom screen with bottom nav
      onGenerateRoute: (settings) {
        if (settings.name == '/rentalBatch') {
          final args = settings.arguments as List<Map<String, dynamic>>;
          return MaterialPageRoute(builder: (context) => RentalBatchScreen(items: args));
        }
        if (settings.name == '/rental') {
          final rentals = settings.arguments as List<Map<String, dynamic>>;
          return MaterialPageRoute(builder: (context) => RentalScreen(rentals: rentals));
        }
        if (settings.name == '/billGeneration') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (context) => BillGenerationScreen(
                    rentals: args['rentals'] ?? [],
                    aadhaarPhotoUri: args['aadhaarPhotoUri'],
                    vehiclePhotoUri: args['vehiclePhotoUri'],
                    status: args['status'] ?? 'pending',
                    customerName: args['customerName'],
                    phoneNumber: args['phoneNumber'],
                    advancePaid: args['advancePaid'],
                    discount: args['discount'],
                  ));
        }
        return null;
      },
    );
  }
}

// MainNavigationScreen with BottomNavigationBar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // List of screens for easy switching
  static const List<Widget> _screens = [
    HomeScreen(),             // Custom HomeScreen with logo and welcome/info
    AvailableItemsScreen(),
    RentalReportScreen(),
    StockManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Stock',
          ),
        ],
      ),
    );
  }
}

// Simple HomeScreen example
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warehouse, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            'Welcome to Rental App',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Use the navigation bar below to switch sections.', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
