import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AddBusinessPage extends StatefulWidget {
  final ApiService api;
  final String token;

  const AddBusinessPage({super.key, required this.api, required this.token});

  @override
  State<AddBusinessPage> createState() => _AddBusinessPageState();
}

class _AddBusinessPageState extends State<AddBusinessPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addrController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  
  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await widget.api.getJson('/businesses/categories');
      setState(() => _categories = res as List<dynamic>);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;
    
    setState(() => _loading = true);
    try {
      await widget.api.postJson('/businesses', {
        'category_id': _selectedCategoryId,
        'name': _nameController.text,
        'description': _descController.text,
        'address': _addrController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'phone': _phoneController.text,
      }, token: widget.token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business listed! Pending verification.')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Add Business')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Business Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: _addrController, decoration: const InputDecoration(labelText: 'Address'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _pincodeController, decoration: const InputDecoration(labelText: 'Pincode'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.brandOrange, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
