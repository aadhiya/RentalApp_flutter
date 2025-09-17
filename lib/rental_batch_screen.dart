import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RentalBatchScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items; // passed selected items

  const RentalBatchScreen({super.key, required this.items});

  @override
  _RentalBatchScreenState createState() => _RentalBatchScreenState();
}

class _RentalBatchScreenState extends State<RentalBatchScreen> {
  late List<Map<String, dynamic>> rentals;

  final DateFormat _dateFormat = DateFormat.yMMMd();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize rentals with inputs and default dates
    rentals = widget.items.map((item) {
      return {
        ...item,
        'quantity': '',
        'advancePaid': '',
        'startDate': DateTime.now(),
        'endDate': DateTime.now(),
      };
    }).toList();
  }

  Future<bool> validateStock() async {
    for (var item in rentals) {
      final docRef =
          FirebaseFirestore.instance.collection('materials').doc(item['id']);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        _showError('Item ${item['name']} not found in stock.');
        return false;
      }
      final currentStock = docSnap.get('quantity') ?? 0;
      final qty = int.tryParse(item['quantity'].toString()) ?? 0;
      if (qty <= 0) {
        _showError('Enter valid quantity for ${item['name']}.');
        return false;
      }
      if (currentStock < qty) {
        _showError(
            'Only $currentStock items available for ${item['name']}.');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> handleSaveRentals() async {
  setState(() => isLoading = true);
  print('handleSaveRentals started with rentals: $rentals');

  final isStockValid = await validateStock();
  print('Stock validation result: $isStockValid');
  
  if (!isStockValid) {
    if (!mounted) return;
    setState(() => isLoading = false);
    print('Exiting due to invalid stock');
    return;
  }

  try {
    for (var item in rentals) {
      print('Processing item ID: ${item['id']} - Name: ${item['name']}');
      final docRef = FirebaseFirestore.instance.collection('materials').doc(item['id']);
      final docSnap = await docRef.get();
      print('Document exists: ${docSnap.exists}');
      if (!docSnap.exists) {
        _showError('Item ${item['name']} not found in stock.');
        setState(() => isLoading = false);
        print('Document not found for item ${item['id']}');
        return;
      }

      final currentStock = docSnap.get('quantity') ?? 0;
      final qty = int.tryParse(item['quantity'].toString()) ?? -1;
      print('Current stock: $currentStock, Requested quantity: $qty');

      if (qty <= 0) {
        _showError('Invalid quantity for ${item['name']}');
        setState(() => isLoading = false);
        print('Invalid quantity for ${item['id']}');
        return;
      }

      await docRef.update({'quantity': currentStock - qty});
      print('Updated item ${item['id']} stock to ${currentStock - qty}');
    }

    final formattedRentals = rentals.map((r) {
  return {
    ...r,
    'quantity': int.parse(r['quantity']),
    'advancePaid': int.tryParse(r['advancePaid'].toString()) ?? 0,
    'startDate': (r['startDate'] as DateTime).toIso8601String(),  // use ISO format
    'endDate': (r['endDate'] as DateTime).toIso8601String(),
  };
}).toList();


    if (!mounted) return;

    setState(() => isLoading = false);
    print('Navigation to rental screen with data: $formattedRentals');

    Navigator.pushNamed(context, '/rental', arguments: formattedRentals);
  } catch (e, stackTrace) {
    if (!mounted) return;
    print('Exception caught during handleSaveRentals: $e');
    print(stackTrace);
    _showError('Failed to update stock.');
    setState(() => isLoading = false);
  }
}



  Future<void> _selectDate(int index, bool isStartDate) async {
    DateTime initialDate =
        isStartDate ? rentals[index]['startDate'] : rentals[index]['endDate'];
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          rentals[index]['startDate'] = picked;
        } else {
          rentals[index]['endDate'] = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Details for Selected Items'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: rentals.asMap().entries.map((entry) {
                  int index = entry.key;
                  var rental = entry.value;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rental['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setState(() {
                                rentals[index]['quantity'] = val;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Text('Start Date: ${_dateFormat.format(rental['startDate'])}'),
                          ElevatedButton(
                            onPressed: () => _selectDate(index, true),
                            child: const Text('Select Start Date'),
                          ),
                          const SizedBox(height: 10),
                          Text('End Date: ${_dateFormat.format(rental['endDate'])}'),
                          ElevatedButton(
                            onPressed: () => _selectDate(index, false),
                            child: const Text('Select End Date'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Advance Paid (optional)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setState(() {
                                rentals[index]['advancePaid'] = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: handleSaveRentals,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
