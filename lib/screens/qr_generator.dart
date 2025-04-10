import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

// This is a utility class to generate QR codes for testing
class QRCodeGenerator extends StatefulWidget {
  const QRCodeGenerator({Key? key}) : super(key: key);

  @override
  State<QRCodeGenerator> createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<QRCodeGenerator> {
  final TextEditingController _idController = TextEditingController(text: "1");
  final TextEditingController _nameController = TextEditingController(text: "Sample Product");
  final TextEditingController _categoryController = TextEditingController(text: "Electronics");
  final TextEditingController _priceController = TextEditingController(text: "9.99");
  final TextEditingController _qrCodeController = TextEditingController(text: "PROD001");
  final TextEditingController _locationController = TextEditingController(text: "Aisle 5");
  final TextEditingController _stockController = TextEditingController(text: "10");
  
  bool _useJsonFormat = true;

  String get qrData {
    if (_useJsonFormat) {
      final Map<String, dynamic> productData = {
        "id": int.tryParse(_idController.text) ?? 1,
        "name": _nameController.text,
        "category": _categoryController.text,
        "price": double.tryParse(_priceController.text) ?? 0.0,
        "qr_code": _qrCodeController.text,
        "location_in_mart": _locationController.text,
        "stock_quantity": int.tryParse(_stockController.text) ?? 0,
        "status": "IN_STORE"
      };
      return jsonEncode(productData);
    } else {
      // Just return the QR code string
      return _qrCodeController.text;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _qrCodeController.dispose();
    _locationController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product QR Code Generator'),
        backgroundColor: const Color(0xFF0CA8E1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a Product QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // QR Code Format Selector
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code Format',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('JSON (Testing)'),
                            value: true,
                            groupValue: _useJsonFormat,
                            onChanged: (value) {
                              setState(() {
                                _useJsonFormat = value!;
                              });
                            },
                            activeColor: const Color(0xFF0CA8E1),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('QR Code Only'),
                            value: false,
                            groupValue: _useJsonFormat,
                            onChanged: (value) {
                              setState(() {
                                _useJsonFormat = value!;
                              });
                            },
                            activeColor: const Color(0xFF0CA8E1),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Note: Use "JSON" for testing and "QR Code Only" for production',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Product Fields
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // QR Code (always required)
                    TextField(
                      controller: _qrCodeController,
                      decoration: const InputDecoration(
                        labelText: 'QR Code Identifier *',
                        border: OutlineInputBorder(),
                        helperText: 'Unique identifier for this product',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    
                    // Only show these fields if using JSON format
                    if (_useJsonFormat) ...[
                      TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'Product ID',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Product Price',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location in Store',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // QR Code Display
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'QR Code Data:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          qrData,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR Code copied to clipboard'),
                              backgroundColor: Color(0xFF0CA8E1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy QR Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0CA8E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Scan this QR code with your app to test',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
