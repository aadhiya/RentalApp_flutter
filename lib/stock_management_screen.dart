import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({Key? key}) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _materials = [];
  bool _loading = false;

  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _loading = true);
    try {
      QuerySnapshot snapshot = await _db.collection('materials').get();
      _materials = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching materials: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addMaterial() async {
    final name = _nameController.text.trim();
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

    if (name.isEmpty || rate <= 0 || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid material details')),
      );
      return;
    }

    try {
      await _db.collection('materials').add({
        'name': name,
        'rate': rate,
        'quantity': quantity,
      });
      _nameController.clear();
      _rateController.clear();
      _quantityController.clear();
      _fetchMaterials();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add material: $e')),
      );
    }
  }

  Future<void> _updateMaterial(String id, Map<String, dynamic> updated) async {
    try {
      await _db.collection('materials').doc(id).update(updated);
      _fetchMaterials();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update material: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Management')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Material Name'),
            ),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rate'),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            ElevatedButton(
              onPressed: _addMaterial,
              child: const Text('Add Material'),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _materials.length,
                      itemBuilder: (context, index) {
                        final material = _materials[index];
                        return ListTile(
                          title: Text(material['name'] ?? 'Unnamed'),
                          subtitle: Text(
                              'Rate: ₹${material['rate']?.toString() ?? '0'}, Quantity: ${material['quantity']?.toString() ?? '0'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(material),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> material) {
    final editRateController =
        TextEditingController(text: material['rate'].toString());
    final editQuantityController =
        TextEditingController(text: material['quantity'].toString());

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Edit ${material['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate'),
                ),
                TextField(
                  controller: editQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final updatedRate =
                      double.tryParse(editRateController.text.trim()) ?? 0;
                  final updatedQuantity =
                      int.tryParse(editQuantityController.text.trim()) ?? 0;
                  if (updatedRate > 0 && updatedQuantity >= 0) {
                    _updateMaterial(material['id'], {
                      'rate': updatedRate,
                      'quantity': updatedQuantity,
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid input')),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        });
  }
}
