import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../payment/payment_screen.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import '../../theme/app_theme.dart';  // Add this import

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  _PlaceOrderScreenState createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  int _copies = 1;
  bool _isColor = false;
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileUrl;
  String _pageSelection = "All Pages";
  String _customPages = "";
  int _totalPages = 1;
  bool _isLoading = false;

  double _calculatePrice() {
    int selectedPages = _pageSelection == "All Pages" ? _totalPages : _customPages.split(',').length;
    double pricePerPage = _isColor ? 2.0 : 1.0;
    return selectedPages * _copies * pricePerPage;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
        _totalPages = 10;
      });
    }
  }

  
  String getMimeType(String fileName) {
  if (fileName.endsWith('.pdf')) {
    return 'application/pdf';
  } else if (fileName.endsWith('.doc')) {
    return 'application/msword';
  } else if (fileName.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  } else {
    return 'application/octet-stream'; // Default binary format
  }
}


Future<String?> uploadToCloudinary(Uint8List fileBytes, String fileName) async {
  try {
    String cloudName = "dtpp4j1w9";

    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(getMimeType(fileName)),
      ),
      "upload_preset": "printx",
      "resource_type": "auto"
    });

    final dio = Dio();
    dio.options.headers = {
      'Content-Type': Headers.multipartFormDataContentType,
    };

    Response response = await dio.post(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      data: formData,
    );

    if (response.statusCode == 200) {
      return response.data["secure_url"];
    }
    return null;
  } catch (e) {
    print("Cloudinary Upload Exception: $e");
    return null;
  }
}


  void _placeOrder() async {
    if (_fileBytes == null || _fileName == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload a file")),
      );
      return;
    }

    setState(() => _isLoading = true);
    String orderId = FirebaseFirestore.instance.collection('orders').doc().id;
    String? fileUrl = await uploadToCloudinary(_fileBytes!, _fileName!);



    if (fileUrl == null) {
      setState(() => _isLoading = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File upload failed. Try again.")),
      );
      return;
    }

    double finalPrice = _calculatePrice();

    OrderModel order = OrderModel(
      id: orderId,
      userId: "user123",
      fileUrl: fileUrl,
      copies: _copies,
      isColor: _isColor,
      status: "Pending",
      price: finalPrice,
      createdAt: Timestamp.now(),
      items: [{'pages': _pageSelection == "All Pages" ? "All" : _customPages}],
      paymentStatus: "Pending",
    );

    await Provider.of<OrderProvider>(context, listen: false).placeOrder(order);
    setState(() => _isLoading = false);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(amount: finalPrice, orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Place Order")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Document",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Select File"),
                    ),
                    if (_fileName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Selected: $_fileName",
                          style: TextStyle(color: AppTheme.textColorSecondary),  // Remove const
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Print Settings",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Color Print",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Switch(
                          value: _isColor,
                          onChanged: (value) => setState(() => _isColor = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Number of Copies",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _copies > 1
                              ? () => setState(() => _copies--)
                              : null,
                        ),
                        Text(
                          _copies.toString(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _copies++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)  // Remove const
                  : const Text("PROCEED TO PAYMENT"),
            ),
          ],
        ),
      ),
    );
  }
}
