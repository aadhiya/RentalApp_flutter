import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';



class RentalScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rentals;
  final String? initialCustomerName;
  final String? initialPhoneNumber;

  const RentalScreen({
    Key? key,
    required this.rentals,
    this.initialCustomerName,
    this.initialPhoneNumber,
  }) : super(key: key);

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _phoneNumberController;
  String _status = 'pending';

  // You can replace these with actual photo file URIs or File objects after integrating flutter camera or image picker
  String? _aadhaarPhotoUri;
  String? _vehiclePhotoUri;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.initialCustomerName ?? '');
    _phoneNumberController = TextEditingController(text: widget.initialPhoneNumber ?? '');
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

 Future<void> _handleCapturePhoto(String mode) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile != null) {
    setState(() {
      if (mode == 'aadhaar') {
        _aadhaarPhotoUri = pickedFile.path;
      } else if (mode == 'vehicle') {
        _vehiclePhotoUri = pickedFile.path;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$mode photo captured"), backgroundColor: Colors.green),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("No photo captured"), backgroundColor: Colors.red),
    );
  }
}

  void _handleConfirm() {
    if (_customerNameController.text.trim().isEmpty) {
      _showAlert('Please enter a customer name.');
      return;
    }
    if (_phoneNumberController.text.trim().isEmpty) {
      _showAlert('Please enter a phone number.');
      return;
    }
    if (_status.isEmpty) {
      _showAlert('Please select a status.');
      return;
    }

    // Proceed to next screen or process further
    // For example, navigate to billing screen passing all details

    Navigator.pushNamed(
      context,
      '/billGeneration', // define this route accordingly
      arguments: {
        'rentals': widget.rentals,
        'aadhaarPhotoUri': _aadhaarPhotoUri,
        'vehiclePhotoUri': _vehiclePhotoUri,
        'status': _status,
        'customerName': _customerNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
      },
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String value) {
    final isSelected = _status == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _status = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? Colors.green : Colors.grey),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Details and Photos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Name', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter customer name',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Phone Number', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter phone number',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Aadhaar Card Photo (optional)', style: TextStyle(fontSize: 16)),
if (_aadhaarPhotoUri != null)
  Image.file(
    File(_aadhaarPhotoUri!),
    height: 150,
  ),
ElevatedButton(
  onPressed: () => _handleCapturePhoto('aadhaar'),
  child: const Text('Capture Aadhaar Card Photo'),
),
const SizedBox(height: 20),
const Text('Vehicle Photo (optional)', style: TextStyle(fontSize: 16)),
if (_vehiclePhotoUri != null)
  Image.file(
    File(_vehiclePhotoUri!),
    height: 150,
  ),
ElevatedButton(
  onPressed: () => _handleCapturePhoto('vehicle'),
  child: const Text('Capture Vehicle Photo'),
),

            const SizedBox(height: 20),
            const Text('Select Status', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                _buildStatusOption('Pending', 'pending'),
                _buildStatusOption('Paid', 'paid'),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirm and Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
