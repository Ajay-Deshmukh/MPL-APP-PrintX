import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/payment_service.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'dart:html' as html;
import '../payment/payment_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  bool _isLoading = false;
  int _copies = 1;
  bool _isColor = false;
  Uint8List? _fileBytes;
  String? _fileName;
  String _pageSelection = "All Pages";
  String _customPages = "";
  int _totalPages = 1;

  String getMimeType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.toLowerCase().endsWith('.doc')) {
      return 'application/msword';
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _fileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
          _totalPages = 10;
        });
      }
    } catch (e) {
      print('File picking error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error selecting file. Please try again.")),
      );
    }
  }

  Future<String?> uploadToCloudinary(Uint8List fileBytes, String fileName) async {
    try {
      String cloudName = "dtpp4j1w9";
      String apiKey = "725718222152461";
      String apiSecret = "cU0Rt6F0ncvN90csKYS6kL0ij3o";
      
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      String signature = await _generateSignature(timestamp, apiSecret);
      
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(getMimeType(fileName)),
        ),
        "api_key": apiKey,
        "timestamp": timestamp.toString(),
        "signature": signature,
      });

      final dio = Dio();
      Response response = await dio.post(
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload",
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data["secure_url"];
      }
      return null;
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  Future<String> _generateSignature(int timestamp, String apiSecret) async {
    final params = 'timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(params);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Add totalPrice variable
  double _totalPrice = 0.0;
  
  void _updatePrice() {
    setState(() {
      int selectedPages = _pageSelection == "All Pages" ? _totalPages : _customPages.split(',').where((s) => s.trim().isNotEmpty).length;
      double pricePerPage = _isColor ? 10.0 : 2.0;
      _totalPrice = selectedPages * _copies * pricePerPage;
    });
  }

  // Remove _calculatePrice() since we're using _updatePrice()
  void _placeOrder() async {
    if (_fileBytes == null || _fileName == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a file")),
      );
      return;
    }

    setState(() => _isLoading = true);
    String orderId = FirebaseFirestore.instance.collection('orders').doc().id;
    
    // Get the current user's ID from Provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;  // Make sure this matches your user model
    
    if (userId == null) {
      setState(() => _isLoading = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    String? fileUrl = await uploadToCloudinary(_fileBytes!, _fileName!);

    if (fileUrl == null) {
      setState(() => _isLoading = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File upload failed. Try again.")),
      );
      return;
    }

    OrderModel order = OrderModel(
      id: orderId,
      userId: userId,  // Use the actual userId from auth
      fileUrl: fileUrl,
      copies: _copies,
      isColor: _isColor,
      status: "Pending",
      price: _totalPrice,
      createdAt: Timestamp.now(),
      items: [{'pages': _pageSelection == "All Pages" ? "All" : _customPages}],
      paymentStatus: "Pending",
    );

    await Provider.of<OrderProvider>(context, listen: false).placeOrder(order);
    setState(() => _isLoading = false);
    
    if (!context.mounted) return;

    // Navigate to PaymentScreen instead of handling payment directly
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: _totalPrice,
          orderId: orderId,
        ),
      ),
    );

    if (result == true) {
      if (!context.mounted) return;
      // Replace Navigator.pop with navigation to dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',  // Make sure this route is defined in your app
        (route) => false,  // This removes all previous routes from the stack
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _updatePrice();
    // Remove _loadRazorpayScript call
  }

  // Remove these methods as they're no longer needed
  // void _loadRazorpayScript() { ... }
  // void _handleWebPayment(String orderId, double amount) { ... }
  void _handleWebPayment(String orderId, double amount) {
    // Wait for Razorpay to be loaded
    if (js.context['Razorpay'] == null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _handleWebPayment(orderId, amount);
      });
      return;
    }

    try {
      js.context['handlePaymentSuccess'] = js.allowInterop((dynamic response) async {
        print('Payment successful');
        if (response != null) {
          String paymentId = response['razorpay_payment_id'];
          await Provider.of<OrderProvider>(context, listen: false)
              .updatePaymentStatus(orderId, "Completed");
          if (!context.mounted) return;
          Navigator.pop(context);
        }
      });

      js.context['handlePaymentError'] = js.allowInterop((dynamic error) {
        print('Payment failed: $error');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment failed. Please try again.")),
        );
      });

      final options = js.JsObject.jsify({
        'key': 'rzp_test_51Jw5RwEwGJjPGK',
        'amount': (amount * 100).toInt(),
        'name': 'PrintX',
        'description': 'Order #$orderId',
        'handler': js.context['handlePaymentSuccess'],
        'prefill': {
          'name': 'Customer Name',
          'email': 'customer@email.com'
        },
        'theme': {
          'color': '#3399cc'
        },
        'modal': {
          'ondismiss': js.context['handlePaymentError']
        }
      });

      final razorpay = js.JsObject(js.context['Razorpay'], [options]);
      razorpay.callMethod('open');
    } catch (e) {
      print('Razorpay Error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment initialization failed. Please try again.")),
      );
    }
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
            // Upload Document Card
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
                          style: TextStyle(color: Colors.grey), // Fixed color
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Print Settings Card
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
                    Text(
                      "Page Selection",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _pageSelection,
                      isExpanded: true,
                      items: ["All Pages", "Custom Pages"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _pageSelection = value!;
                          _updatePrice();
                        });
                      },
                    ),
                    if (_pageSelection == "Custom Pages")
                      TextField(
                        decoration: const InputDecoration(
                          hintText: "e.g., 1,3,5-8",
                          helperText: "Enter page numbers separated by commas, or ranges with '-'",
                        ),
                        onChanged: (value) {
                          setState(() {
                            _customPages = value;
                            _updatePrice();
                          });
                        },
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
                          onChanged: (value) {
                            setState(() {
                              _isColor = value;
                              _updatePrice();
                            });
                          },
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("PROCEED TO PAYMENT"),
            ),
            const SizedBox(height: 16),
            // Price Summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price Summary",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Price per page:"),
                        Text("₹${_isColor ? "10.00" : "2.00"}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Number of pages:"),
                        Text("${_pageSelection == "All Pages" ? _totalPages : _customPages.split(',').where((s) => s.trim().isNotEmpty).length}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Number of copies:"),
                        Text("$_copies"),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Amount:",
                            style: Theme.of(context).textTheme.titleMedium),
                        Text("₹${_totalPrice.toStringAsFixed(2)}",
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}