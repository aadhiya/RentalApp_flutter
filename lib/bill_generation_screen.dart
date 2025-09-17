import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/services.dart' show PlatformException;



class BillGenerationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rentals;
  final String? aadhaarPhotoUri;
  final String? vehiclePhotoUri;
  final String status;
  final String? customerName;
  final String? phoneNumber;
  final double? advancePaid;
  final double? discount;


  const BillGenerationScreen({
    Key? key,
    required this.rentals,
    this.aadhaarPhotoUri,
    this.vehiclePhotoUri,
    this.status = 'pending',
    this.customerName,
    this.phoneNumber,
    this.advancePaid,
    this.discount,
  }) : super(key: key);

  @override
  State<BillGenerationScreen> createState() => _BillGenerationScreenState();
}

class _BillGenerationScreenState extends State<BillGenerationScreen> {
  final DateFormat dateFormat = DateFormat.yMMMd();

  late List<Map<String, dynamic>> editedRentals;

  late TextEditingController customerNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController discountController;
  late TextEditingController advancePaidController;

  double discountNum = 0;
  double advanceNum = 0;
  double finalAmount = 0;

  bool isSaving = false;
  static const MethodChannel platform = MethodChannel('com.example.rentalapp/printer');

  String? selectedPrinterIp;
  late pw.Font spaceMonoFont;

  @override
  void initState() {
    super.initState();

    editedRentals = widget.rentals.map((r) {
      int days = getNumberOfDays(r['startDate'], r['endDate']);
      double quantity = (r['quantity'] is num) ? r['quantity'].toDouble() : 0;
      double rate = (r['rate'] is num) ? r['rate'].toDouble() : 0;
      double totalAmount = days * quantity * rate;
      return {
        ...r,
        'days': days,
        'totalAmount': totalAmount,
      };
    }).toList();

    customerNameController = TextEditingController(text: widget.customerName ?? '');
    phoneNumberController = TextEditingController(text: widget.phoneNumber ?? '');
    discountController = TextEditingController(text: (widget.discount ?? 0).toString());
    advancePaidController = TextEditingController(text: (widget.advancePaid ?? 0).toString());

    discountController.addListener(_updateFinalAmount);
    advancePaidController.addListener(_updateFinalAmount);

    _loadFontAndInit();
  }

  Future<void> _loadFontAndInit() async {
    final fontData = await rootBundle.load('assets/fonts/SpaceMono-Regular.ttf');
    setState(() {
      spaceMonoFont = pw.Font.ttf(fontData);
    });
    _updateFinalAmount();
  }

  @override
  void dispose() {
    customerNameController.dispose();
    phoneNumberController.dispose();
    discountController.dispose();
    advancePaidController.dispose();
    super.dispose();
  }

  int getNumberOfDays(String start, String end) {
    try {
      DateTime s = DateTime.parse(start);
      DateTime e = DateTime.parse(end);
      int diff = e.difference(s).inDays;
      return diff < 0 ? 0 : diff + 1;
    } catch (e) {
      return 0; // fallback
    }
  }

  double get sumTotalAmount =>
      editedRentals.fold(0, (acc, r) => acc + (r['totalAmount'] ?? 0));

  void _updateFinalAmount() {
    setState(() {
      discountNum = double.tryParse(discountController.text) ?? 0;
      advanceNum = double.tryParse(advancePaidController.text) ?? 0;
      finalAmount = (sumTotalAmount - discountNum - advanceNum).clamp(0, double.infinity);
    });
  }

  Future<void> saveBill() async {
    setState(() => isSaving = true);
    try {
      List<Map<String, dynamic>> itemsArray = editedRentals.map((item) {
        return {
          'itemId': item['id'],
          'itemName': item['name'] ?? 'N/A',
          'startDate': item['startDate'] ?? '',
          'endDate': item['endDate'] ?? '',
          'quantity': item['quantity'] ?? 0,
          'rate': item['rate'] ?? 0,
          'days': item['days'] ?? 0,
          'totalAmount': item['totalAmount'] ?? 0,
          'advancePaid': item['advancePaid'] ?? 0,
        };
      }).toList();

      final billData = {
        'name': customerNameController.text.isNotEmpty ? customerNameController.text : 'Unknown',
        'mobileNumber': phoneNumberController.text,
        'advancePaid': advanceNum,
        'discountNum': discountNum,
        'finalAmount': finalAmount,
        'totalAmount': sumTotalAmount,
        'items': itemsArray,
        'status': widget.status,
        'aadhaarPhoto': widget.aadhaarPhotoUri ?? null,
        'vehiclePhoto': widget.vehiclePhotoUri ?? null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      final docRef = await FirebaseFirestore.instance.collection('customers').add(billData);

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill saved with ID: ${docRef.id}')),
      );
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save bill: $e')),
      );
    }
  }


  Future<Uint8List> generatePdfData() async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Estimate / Quotation',
                style: pw.TextStyle(font: spaceMonoFont, fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Customer Name: ${customerNameController.text}', style: pw.TextStyle(font: spaceMonoFont)),
            pw.Text('Phone Number: ${phoneNumberController.text}', style: pw.TextStyle(font: spaceMonoFont)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Item', 'Qty', 'Rate', 'Days', 'Total'],
              data: editedRentals
                  .map((r) => [
                        r['name'],
                        r['quantity'].toString(),
                        r['rate'].toStringAsFixed(2),
                        r['days'].toString(),
                        r['totalAmount'].toStringAsFixed(2)
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Total Amount: ₹${sumTotalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(font: spaceMonoFont)),
            pw.Text('Discount: ₹${discountNum.toStringAsFixed(2)}',
                style: pw.TextStyle(font: spaceMonoFont)),
            pw.Text('Advance Paid: ₹${advanceNum.toStringAsFixed(2)}',
                style: pw.TextStyle(font: spaceMonoFont)),
            pw.Text('Final Amount: ₹${finalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(font: spaceMonoFont)),
          ],
        );
      },
    ));

    return pdf.save();
  }
String generatePlainTextBill() {
  final buffer = StringBuffer();
  buffer.writeln('Estimate / Quotation\n');
  buffer.writeln('Customer: ${customerNameController.text}');
  buffer.writeln('Phone: ${phoneNumberController.text}\n');
  buffer.writeln('Item   Qty  Rate  Days  Total');
  for (final r in editedRentals) {
    buffer.writeln('${r['name']}  ${r['quantity']}  ${r['rate']}  ${r['days']}  ₹${r['totalAmount'].toStringAsFixed(2)}');
  }
  buffer.writeln('\nTotal: ₹${sumTotalAmount.toStringAsFixed(2)}');
  buffer.writeln('Discount: ₹${discountNum.toStringAsFixed(2)}');
  buffer.writeln('Advance: ₹${advanceNum.toStringAsFixed(2)}');
  buffer.writeln('Final: ₹${finalAmount.toStringAsFixed(2)}');
  return buffer.toString();
}

Future<void> handleNativePrint(String type) async {
  if (selectedPrinterIp == null || selectedPrinterIp!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select or enter a printer IP to print.')),
    );
    return;
  }

  try {
    // Generate plain text bill for thermal printer
    String billText = generatePlainTextBill();

    final result = await platform.invokeMethod('printBill', {
      'printerIp': selectedPrinterIp,
      'billText': billText,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Printer $selectedPrinterIp: $result')),
    );
  } on PlatformException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Print Error: ${e.message ?? 'Could not print'}')),
    );
  }
}


  void sharePdf() async {
    final pdfData = await generatePdfData();
    await Printing.sharePdf(bytes: pdfData, filename: 'rental_bill.pdf');
  }

  void printBill({String size = 'A4'}) async {
    final pdfData = await generatePdfData();
    PdfPageFormat format;

    if (size == '80mm') {
      format = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity);
    } else {
      format = PdfPageFormat.a4;
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      format: format,
    );
  }

  // Additional 80mm printer scanning and manual IP input handling

  List<String> discoveredPrinters = [];
  
  String manualIp = '';
  bool isScanning = false;

  Future<void> discoverPrinters() async {
  setState(() {
    isScanning = true;
    discoveredPrinters = [];
  });

  try {
    final List<dynamic> ips = await platform.invokeMethod('discoverPrinters');
    setState(() {
      discoveredPrinters = ips.cast<String>();
      isScanning = false;
    });
  } catch (e) {
    setState(() {
      isScanning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to discover printers: $e')),
    );
  }
}


  void stopScanning() {
    // TODO: Implement platform specific stop scan logic if any
    setState(() {
      isScanning = false;
    });
  }

  void setSelectedPrinter(String ip) {
    setState(() {
      selectedPrinterIp = ip;
      manualIp = ip;
    });
  }

 void printTo80mmPrinter() {
  if (selectedPrinterIp == null || selectedPrinterIp!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select or enter a printer IP')),
    );
    return;
  }
  handleNativePrint('bill'); // calls native printing with plain text bill
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Generation'),
      ),
      body: isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: customerNameController,
                    decoration: const InputDecoration(labelText: 'Customer Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneNumberController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: discountController,
                    decoration: const InputDecoration(labelText: 'Discount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: advancePaidController,
                    decoration: const InputDecoration(labelText: 'Advance Paid'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Rental Items:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: editedRentals.length,
                    itemBuilder: (context, index) {
                      final rental = editedRentals[index];
                      return ListTile(
                        title: Text(rental['name'] ?? 'Item'),
                        subtitle: Text(
                          'Qty: ${rental['quantity']} | Rate: ${rental['rate']} | Days: ${rental['days']} | Total: ₹${rental['totalAmount'].toStringAsFixed(2)}',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Final Amount: ₹${finalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),

                  // Printer setup UI
                  Text('Printer Setup:', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isScanning ? null : discoverPrinters,
                    child: Text(isScanning ? 'Scanning...' : 'Scan for Printers'),
                  ),
                  ElevatedButton(
                    onPressed: isScanning ? stopScanning : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Stop Scanning'),
                  ),
                  const SizedBox(height: 10),
                  Text('Discovered Printers:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  discoveredPrinters.isEmpty
                      ? const Text('No printers found')
                      : Wrap(
                          spacing: 8,
                          children: discoveredPrinters.map((ip) {
                            final selected = ip == selectedPrinterIp;
                            return ChoiceChip(
                              label: Text(ip),
                              selected: selected,
                              onSelected: (_) => setSelectedPrinter(ip),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 10),
                  Text('Manual Printer IP:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter printer IP manually',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => manualIp = val),
                    controller: TextEditingController(text: manualIp),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (manualIp.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a printer IP address')),
                        );
                        return;
                      }
                      setSelectedPrinter(manualIp);
                    },
                    child: const Text('Set as Printer IP'),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: sharePdf,
                        child: const Text('Share Bill (PDF)'),
                      ),
                      ElevatedButton(
                        onPressed: () => printBill(size: 'A4'),
                        child: const Text('Print A4'),
                      ),
                      ElevatedButton(
                        onPressed: () => handleNativePrint('bill'),
                        child: const Text('Print 80mm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: saveBill,
                    child: const Text('Save Bill'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
