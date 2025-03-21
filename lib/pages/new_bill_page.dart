import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitgasy/services/balance_service.dart';

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
  String? _selectedSplitMethod;
  bool _isSubmitting = false;
  double _amount = 0.0;
  List<Map<String, dynamic>> _participants = [];

  // Split methods
  final List<String> _splitMethods = [
    'Equal',
    'Proportional',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _initializeParticipants();
  }

  void _initializeParticipants() {
    _participants = widget.groupMembers.map((member) => {
      'id': member['id'],
      'name': member['name'],
      'share': 0.0,
    }).toList();
  }

  @override
  void dispose() {
    _billNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitBill() async {
    if (!_formKey.currentState!.validate() || _selectedPayer == null || _selectedSplitMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
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

      final amount = double.parse(_amountController.text);
      final equalShare = amount / widget.groupMembers.length;

      // Create the bill document
      final billData = {
        'name': _billNameController.text.trim(),
        'groupId': widget.groupId,
        'paidById': _selectedPayer,
        'amount': amount,
        'date': Timestamp.now(),
        'splitMethod': _selectedSplitMethod?.toLowerCase() ?? 'equal',
        'participants': widget.groupMembers.map((member) => {
          ...member,
          'share': equalShare,
          'paid': member['id'] == _selectedPayer,
        }).toList(),
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
        (billData['participants'] as List).cast<Map<String, dynamic>>(),
      );

      // Get the group name for the activity notification
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Get the creator's name
      final creatorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final creatorName = creatorDoc.data()?['name'] ?? 'Unknown User';

      // Create activity notifications for all participants
      final batch = FirebaseFirestore.instance.batch();
      for (var participant in widget.groupMembers) {
        // Create notification for everyone, including the creator
        final activityRef = FirebaseFirestore.instance
            .collection('users')
            .doc(participant['id'])
            .collection('activity')
            .doc();

        batch.set(activityRef, {
          'type': 'expense_update',
          'fromUserId': currentUser.uid,
          'fromUserName': creatorName,
          'groupId': widget.groupId,
          'groupName': groupName,
          'amount': amount,
          'expenseName': _billNameController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'isCreator': participant['id'] == currentUser.uid,  // Add flag to identify if this is the creator's notification
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
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
          child: Column(
            children: [
              // Top Section (Styled like Home Page)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF043E50),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bill Name Input
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
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              errorStyle: const TextStyle(
                                color: Color(0xFFFFC2C2),
                                fontSize: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a bill name';
                              }
                              return null;
                            },
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
                        color: Colors.black26,
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
                        items: widget.groupMembers.map((member) {
                          return DropdownMenuItem(
                            value: member['id'] as String,
                            child: Text(member['name'] as String),
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

                    // Split Method Section
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
                        color: Colors.black26,
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
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    border: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an amount';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rest of the form fields
              Expanded(
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.only(top: 30),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : _submitBill,
        elevation: 0,
        backgroundColor:  Colors.black26,
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
