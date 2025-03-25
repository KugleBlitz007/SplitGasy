import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitgasy/services/balance_service.dart';
import 'package:google_fonts/google_fonts.dart';

class NewBillPage extends StatefulWidget {
  final String groupId;
  final List<Map<String, dynamic>> groupMembers;

  const NewBillPage({
    super.key,
    required this.groupId,
    required this.groupMembers,
  });

  @override
  _NewBillPageState createState() => _NewBillPageState();
}

class _NewBillPageState extends State<NewBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _billNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPayer;
  String? _selectedSplitMethod = 'Equal';
  bool _isSubmitting = false;
  Map<String, TextEditingController> _shareControllers = {};
  Map<String, TextEditingController> _percentageControllers = {};

  // Split methods
  final List<String> _splitMethods = [
    'Equal',
    'Proportional',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var member in widget.groupMembers) {
      _shareControllers[member['id']] = TextEditingController();
      _percentageControllers[member['id']] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _billNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _shareControllers.values.forEach((controller) => controller.dispose());
    _percentageControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _updateShares() {
    if (_amountController.text.isEmpty) return;
    
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    
    switch (_selectedSplitMethod) {
      case 'Equal':
        final equalShare = (totalAmount / widget.groupMembers.length).toStringAsFixed(2);
        for (var member in widget.groupMembers) {
          _shareControllers[member['id']]?.text = equalShare;
        }
        break;
        
      case 'Proportional':
        double totalPercentage = 0;
        for (var controller in _percentageControllers.values) {
          totalPercentage += double.tryParse(controller.text) ?? 0;
        }
        
        if (totalPercentage > 0) {
          for (var member in widget.groupMembers) {
            final percentage = double.tryParse(_percentageControllers[member['id']]?.text ?? '0') ?? 0;
            final share = (totalAmount * percentage / 100).toStringAsFixed(2);
            _shareControllers[member['id']]?.text = share;
          }
        }
        break;
        
      case 'Custom':
        // Custom shares are managed directly through share controllers
        break;
    }
  }

  Future<void> _submitBill() async {
    if (!_formKey.currentState!.validate() || _selectedPayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate total shares equals total amount
    final totalAmount = double.parse(_amountController.text);
    double totalShares = 0;
    
    for (var controller in _shareControllers.values) {
      totalShares += double.tryParse(controller.text) ?? 0;
    }

    if ((totalShares - totalAmount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total shares must equal the bill amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Create participants list with shares
      final participants = widget.groupMembers.map((member) => {
        ...member,
        'share': double.parse(_shareControllers[member['id']]!.text),
        'paid': member['id'] == _selectedPayer,
      }).toList();

      // Create the bill document
      final billData = {
        'name': _billNameController.text.trim(),
        'groupId': widget.groupId,
        'paidById': _selectedPayer,
        'amount': totalAmount,
        'date': Timestamp.now(),
        'splitMethod': _selectedSplitMethod?.toLowerCase() ?? 'equal',
        'participants': participants,
        'createdBy': currentUser.uid,
        'createdAt': Timestamp.now(),
      };

      // Add the bill to Firestore
      final billRef = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('bills')
          .add(billData);

      // Update balances for the new bill
      await BalanceService.updateBalancesForBill(
        widget.groupId,
        billRef.id,
        _selectedPayer!,
        participants,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: const Color(0xFF043E50),
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Top Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF043E50),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bill Name and Close Button
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
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
                                border: InputBorder.none,
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Amount Field
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Amount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  '\$',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white38),
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white38),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (double.tryParse(value!) == null) return 'Invalid amount';
                                      return null;
                                    },
                                    onChanged: (value) => _updateShares(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Paid By Section
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<String>(
                          value: _selectedPayer,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF043E50),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          items: widget.groupMembers.map((member) {
                            return DropdownMenuItem<String>(
                              value: member['id'] as String,
                              child: Text(member['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedPayer = value),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Split Method Section
                      const Text(
                        'Split Method',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<String>(
                          value: _selectedSplitMethod,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF043E50),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          items: _splitMethods.map((String method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(method),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSplitMethod = value;
                              _updateShares();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Split Method Content
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildSplitMethodContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : _submitBill,
        elevation: 0,
        backgroundColor: const Color(0xFF043E50),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildSplitMethodContent() {
    if (_amountController.text.isEmpty) {
      return const Center(
        child: Text(
          'Enter an amount first',
          style: TextStyle(color: Color(0xFF043E50)),
        ),
      );
    }

    final totalAmount = double.tryParse(_amountController.text) ?? 0;

    switch (_selectedSplitMethod) {
      case 'Equal':
        final equalShare = totalAmount / widget.groupMembers.length;
        return Column(
          children: widget.groupMembers.map((member) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    member['name'],
                    style: const TextStyle(
                      color: Color(0xFF043E50),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${equalShare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF043E50),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 'Proportional':
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Set percentage for each person',
                style: TextStyle(
                  color: Color(0xFF043E50),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...widget.groupMembers.map((member) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        member['name'],
                        style: const TextStyle(
                          color: Color(0xFF043E50),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _percentageControllers[member['id']],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF043E50),
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          suffix: Text('%'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => _updateShares(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '\$${_shareControllers[member['id']]?.text ?? '0.00'}',
                        style: const TextStyle(
                          color: Color(0xFF043E50),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );

      case 'Custom':
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Enter custom amount for each person',
                style: TextStyle(
                  color: Color(0xFF043E50),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...widget.groupMembers.map((member) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        member['name'],
                        style: const TextStyle(
                          color: Color(0xFF043E50),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _shareControllers[member['id']],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF043E50),
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '\$',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
