import 'package:flutter/material.dart';
import 'package:splitgasy/components/custom_text_field.dart'; // Import your custom text field

class NewBillPage extends StatefulWidget {
  const NewBillPage({super.key});

  @override
  _NewBillPageState createState() => _NewBillPageState();
}

class _NewBillPageState extends State<NewBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _billNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPayer; // To store who paid the bill
  String? _selectedSplitMethod; // To store selected split method

  // Sample list of group members (replace with actual data from your app)
  final List<String> _groupMembers = [
    'Matitika',
    'Dera',
    'Johann',
    'Syd',
  ];

  // Sample list of split methods (replace with actual data from your app)
  final List<String> _splitMethods = [
    'Equal',
    'Proportional',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _billNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitBill() {
    if (_formKey.currentState!.validate()) {
      // Handle bill submission (e.g., save to Firestore or state)
      final billName = _billNameController.text;
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final paidBy = _selectedPayer;

      // For now, just print the bill details
      print('Bill Name: $billName');
      print('Amount: $amount');
      print('Description: $description');
      print('Paid By: $paidBy');

      // Optionally, navigate back to the previous page
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: const Color(0xFF333533),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Section (Styled like Home Page)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF333533), // Darker color for top section
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bill Name Input (Transparent TextField)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _billNameController,
                            autofocus: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Bill Name...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    

                    // Who Paid Section
                    const Text(
                      'Paid by',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPayer,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        dropdownColor: Colors.grey.shade900,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        hint: Text(
                          'Select payer',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        items: _groupMembers.map((member) {
                          return DropdownMenuItem(
                            value: member,
                            child: Text(member),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPayer = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Split Section
                    const Text(
                      'Split...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSplitMethod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        dropdownColor: Colors.grey.shade900,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        hint: Text(
                          'Select split method',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        items: _splitMethods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSplitMethod = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // Rest of the form fields
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.only(top: 20),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount Field
                          CustomTextField(
                            controller: _amountController,
                            hintText: 'Amount',
                            obscureText: false,
                          ),
                          const SizedBox(height: 20),

                          // Description Field
                          CustomTextField(
                            controller: _descriptionController,
                            hintText: 'Description (Optional)',
                            obscureText: false,
                          ),
                          const SizedBox(height: 30),

                          // Submit Button
                          Center(
                            child: ElevatedButton(
                              onPressed: _submitBill,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF333533),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Create Bill',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
