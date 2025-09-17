import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AvailableItemsScreen extends StatefulWidget {
  const AvailableItemsScreen({super.key});

  @override
  State<AvailableItemsScreen> createState() => _AvailableItemsScreenState();
}

class _AvailableItemsScreenState extends State<AvailableItemsScreen> {
  List<Map<String, dynamic>> _materials = [];
  final List<Map<String, dynamic>> _selectedItems = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('materials').get();
      final items = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      setState(() {
        _materials = items;
        _loading = false;
      });

      Fluttertoast.showToast(msg: "Materials loaded successfully!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load materials");
      setState(() {
        _loading = false;
      });
    }
  }

  void toggleSelectItem(Map<String, dynamic> item) {
    if (_selectedItems.any((element) => element['id'] == item['id'])) {
      setState(() {
        _selectedItems.removeWhere((element) => element['id'] == item['id']);
      });
    } else {
      if (item['quantity'] == null || item['quantity'] <= 0) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Out of Stock'),
            content: Text('Item "${item['name']}" is currently out of stock.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
          ),
        );
        return;
      }
      setState(() {
        _selectedItems.add(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaterials = _searchQuery.isEmpty
        ? _materials
        : _materials.where((item) {
            final name = item['name']?.toLowerCase() ?? '';
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Materials'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final item = filteredMaterials[index];
                      final isSelected = _selectedItems.any((e) => e['id'] == item['id']);
                      return Card(
                        color: isSelected ? Colors.lightGreen[100] : null,
                        child: ListTile(
                          title: Text(item['name'] ?? ''),
                          subtitle: Text('Rate per day: ₹${item['rate'] ?? 'N/A'}\nAvailable: ${item['quantity'] ?? 0}'),
                          trailing: isSelected ? Icon(Icons.check_circle, color: Colors.green) : null,
                          onTap: () => toggleSelectItem(item),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedItems.isEmpty) {
                        Fluttertoast.showToast(msg: 'Please select at least one item');
                      } else {
                        // Navigate to next screen with selected items
                        Navigator.pushNamed(context, '/rentalBatch', arguments: _selectedItems);
                      }
                    },
                    child: Text('Next'),
                  ),
                )
              ],
            ),
    );
  }
}
