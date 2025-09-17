import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalReportScreen extends StatefulWidget {
  const RentalReportScreen({Key? key}) : super(key: key);

  @override
  State<RentalReportScreen> createState() => _RentalReportScreenState();
}

class _RentalReportScreenState extends State<RentalReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>> _rents = [];
  bool _loading = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchRents();
  }

  Future<void> _fetchRents() async {
    setState(() => _loading = true);
    try {
      Query query = _db.collection('customers')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate));
      QuerySnapshot snapshot = await query.get();
      _rents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch rents: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: _endDate,
    );
    if (picked != null && picked.isBefore(_endDate)) {
      setState(() => _startDate = picked);
      _fetchRents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid start date')),
      );
    }
  }

  Future<void> _selectEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked.isAfter(_startDate)) {
      setState(() => _endDate = picked);
      _fetchRents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid end date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Report')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: _selectStartDate,
                  child: Text('Start: ${_startDate.toLocal().toString().split(' ')[0]}'),
                ),
                TextButton(
                  onPressed: _selectEndDate,
                  child: Text('End: ${_endDate.toLocal().toString().split(' ')[0]}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _rents.length,
                      itemBuilder: (context, index) {
                        final rent = _rents[index];
                        return ListTile(
                          title: Text(rent['name'] ?? 'Unknown Customer'),
                          subtitle: Text('Item: ${rent['itemName'] ?? 'N/A'}, '
                              'Qty: ${rent['quantity'] ?? 0}, '
                              'Rate: ₹${rent['rate'] ?? 0}, '
                              'Date: ${rent['createdAt'] != null ? (rent['createdAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'}'),
                          trailing: Text('Amt: ₹${((rent['quantity'] ?? 0) * (rent['rate'] ?? 0)).toStringAsFixed(2)}'),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
