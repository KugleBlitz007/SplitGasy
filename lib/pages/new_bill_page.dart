import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splizzy/services/balance_service.dart';
import 'package:splizzy/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

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
  final Map<String, TextEditingController> _shareControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};
  final Map<String, TextEditingController> _customAmountControllers = {};

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
      _customAmountControllers[member['id']] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _billNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    for (var controller in _shareControllers.values) {
      controller.dispose();
    }
    for (var controller in _percentageControllers.values) {
      controller.dispose();
    }
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateShares() {
    if (_amountController.text.isEmpty) return;
    
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    
    switch (_selectedSplitMethod) {
      case 'Equal':
        final int numMembers = widget.groupMembers.length;
        final equalShare = (totalAmount / numMembers).toStringAsFixed(2);
        final double equalShareValue = double.parse(equalShare);
        
        // Calculate how much we might be off due to rounding
        final double roundingDifference = totalAmount - (equalShareValue * numMembers);
        
        // Assign equal shares to all members except the last one
        for (int i = 0; i < numMembers - 1; i++) {
          final member = widget.groupMembers[i];
          _shareControllers[member['id']]?.text = equalShare;
        }
        
        // Adjust the last member's share to make the total exact
        if (numMembers > 0) {
          final lastMember = widget.groupMembers[numMembers - 1];
          final lastShare = (equalShareValue + roundingDifference).toStringAsFixed(2);
          _shareControllers[lastMember['id']]?.text = lastShare;
        }
        break;
        
      case 'Proportional':
        double totalPercentage = 0;
        for (var controller in _percentageControllers.values) {
          totalPercentage += double.tryParse(controller.text) ?? 0;
        }
        
        // Update shares based on percentages
        for (var member in widget.groupMembers) {
          final percentage = double.tryParse(_percentageControllers[member['id']]?.text ?? '0') ?? 0;
          final share = (totalAmount * percentage / 100).toStringAsFixed(2);
          _shareControllers[member['id']]?.text = share;
        }
        break;
        
      case 'Custom':
        // Update share controllers based on custom amount controllers
        for (var member in widget.groupMembers) {
          final customAmount = double.tryParse(_customAmountControllers[member['id']]?.text ?? '0') ?? 0;
          _shareControllers[member['id']]?.text = customAmount.toStringAsFixed(2);
        }
        break;
    }
  }

  void _initializeProportionalSplit() {
    // Calculate equal percentage for each member
    final equalPercentage = (100.0 / widget.groupMembers.length).toStringAsFixed(1);
    
    // Set the percentage for each member
    for (var member in widget.groupMembers) {
      _percentageControllers[member['id']]?.text = equalPercentage;
    }
    
    // Update the shares
    _updateShares();
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
      
      // Get group name for notification
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      final groupName = groupDoc.data()?['name'] as String? ?? 'Group';
      
      // Create activity notifications for all participants
      await NotificationService.createBillNotifications(
        groupId: widget.groupId,
        groupName: groupName,
        billId: billRef.id,
        billName: _billNameController.text.trim(),
        amount: totalAmount,
        creatorId: currentUser.uid,
        creatorName: currentUser.displayName ?? 'User',
        participants: participants,
      );
      
      // Update the group's updatedAt field
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
            'updatedAt': FieldValue.serverTimestamp(),
          });

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

                      const SizedBox(height: 10),

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
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                              if (value == 'Proportional') {
                                _initializeProportionalSplit();
                              }
                              _updateShares();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
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
        return Column(
          children: widget.groupMembers.map((member) {
            // Use the value from the share controller
            final shareValue = _shareControllers[member['id']]?.text ?? '0.00';
            
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
                    '\$$shareValue',
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
        // Calculate total percentage
        double totalPercentage = 0;
        for (var controller in _percentageControllers.values) {
          totalPercentage += double.tryParse(controller.text) ?? 0;
        }
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  const Text(
                    'Set percentage for each person',
                    style: TextStyle(
                      color: Color(0xFF043E50),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (totalPercentage - 100).abs() < 0.01
                          ? const Color(0xFFDCFCE7).withOpacity(0.5)
                          : const Color(0xFFFEE2E2).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Total: ${totalPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: (totalPercentage - 100).abs() < 0.01
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
                        onChanged: (value) {
                          setState(() {
                            _updateShares();
                          });
                        },
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
            }),
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
                      child: TextFormField(
                        controller: _customAmountControllers[member['id']],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: '\$',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF043E50)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF043E50),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _updateShares();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
