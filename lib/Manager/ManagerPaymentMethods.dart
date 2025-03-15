import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// UPI Payment Configuration Model
class UPIDetails {
  final String id;
  String upiId; // e.g. merchant@okicici
  String merchantName; // Name that appears during payment
  String? displayName;
  bool isPrimary;
  bool isActive;
  String? bankName; // Associated bank
  String? upiApp; // e.g. Google Pay, PhonePe, BHIM, etc.

  UPIDetails({
    required this.id,
    required this.upiId,
    required this.merchantName,
    this.displayName,
    this.isPrimary = false,
    this.isActive = true,
    this.bankName,
    this.upiApp,
  });

  // Convert to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'upiId': upiId,
      'merchantName': merchantName,
      'displayName': displayName,
      'isPrimary': isPrimary,
      'isActive': isActive,
      'bankName': bankName,
      'upiApp': upiApp,
    };
  }

  // Create from a Map from Firebase
  factory UPIDetails.fromMap(Map<String, dynamic> map) {
    return UPIDetails(
      id: map['id'] ?? const Uuid().v4(),
      upiId: map['upiId'],
      merchantName: map['merchantName'],
      displayName: map['displayName'],
      isPrimary: map['isPrimary'] ?? false,
      isActive: map['isActive'] ?? true,
      bankName: map['bankName'],
      upiApp: map['upiApp'],
    );
  }
}

class ManagerPaymentMethods extends StatefulWidget {
  const ManagerPaymentMethods({Key? key}) : super(key: key);

  @override
  State<ManagerPaymentMethods> createState() => ManagerPaymentMethodsState();
}

class ManagerPaymentMethodsState extends State<ManagerPaymentMethods> {
  // Mock data - will be replaced with Firebase Realtime Database
  List<UPIDetails> _upiAccounts = [
  ];
  String id = '';

  bool _acceptUPI = true; // Global switch to enable/disable UPI payment

  // Add a new UPI account
  void _addUPIAccount() async {
    final result = await showDialog<UPIDetails>(
      context: context,
      builder: (context) => AddEditUPIDialog(),
    );

    if (result != null) {
      setState(() {
        // If this is the first UPI account, make it primary
        if (_upiAccounts.isEmpty) {
          result.isPrimary = true;
        }
        // Otherwise, if this is marked primary, update others
        else if (result.isPrimary) {
          for (var account in _upiAccounts) {
            account.isPrimary = false;
          }
        }
        _upiAccounts.add(result);
      });

      FirebaseDatabase.instance
          .ref()
          .child(id)
          .child('upi_accounts')
          .child(result.id)
          .set(result.toMap());
    }
  }

  // Edit an existing UPI account
  void _editUPIAccount(UPIDetails account) async {
    final result = await showDialog<UPIDetails>(
      context: context,
      builder: (context) => AddEditUPIDialog(upiDetails: account),
    );

    if (result != null) {
      setState(() {
        final index =
            _upiAccounts.indexWhere((element) => element.id == result.id);
        if (index != -1) {
          // If this is being set as primary, update others
          if (result.isPrimary && !_upiAccounts[index].isPrimary) {
            for (var account in _upiAccounts) {
              account.isPrimary = false;
            }
          }
          _upiAccounts[index] = result;
        }
      });

      // TODO: Update Firebase Realtime Database
      // Example code:
      FirebaseDatabase.instance
          .ref()
          .child(id)
          .child('upi_accounts')
          .child(result.id)
          .update(result.toMap());
    }
  }

  // Delete a UPI account
  void _deleteUPIAccount(String id) async {
    // Check if this is the primary account
    final isPrimary =
        _upiAccounts.firstWhere((element) => element.id == id).isPrimary;

    if (isPrimary && _upiAccounts.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot delete primary UPI account. Set another account as primary first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete UPI Account'),
        content:
            const Text('Are you sure you want to delete this UPI account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _upiAccounts.removeWhere((element) => element.id == id);

        // If we just removed the primary account and others exist, make one primary
        if (isPrimary && _upiAccounts.isNotEmpty) {
          _upiAccounts.first.isPrimary = true;
        }
      });

      // TODO: Update Firebase Realtime Database
      // Example code:
      FirebaseDatabase.instance.ref().child(id).child('upi_accounts').child(id).remove();
    }
  }

  // Toggle the active status of a UPI account
  void _toggleUPIAccountStatus(String idd) {
    setState(() {
      final index = _upiAccounts.indexWhere((element) => element.id == id);
      if (index != -1) {
        _upiAccounts[index].isActive = !_upiAccounts[index].isActive;

        // TODO: Update Firebase Realtime Database
        // Example code:
        FirebaseDatabase.instance
            .ref()
            .child(id)
            .child('upi_accounts')
            .child(idd)
            .update({'isActive': _upiAccounts[index].isActive});
      }
    });
  }

  // Set UPI account as primary
  void _setPrimaryUPIAccount(String id) {
    setState(() {
      for (var account in _upiAccounts) {
        account.isPrimary = account.id == id;
      }

      // TODO: Update Firebase Realtime Database for all accounts
      // Example code:
      for (var account in _upiAccounts) {
        FirebaseDatabase.instance
            .ref()
            .child(id)
            .child('upi_accounts')
            .child(account.id)
            .update({'isPrimary': account.isPrimary});
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // TODO: Initialize Firebase and load data from Firebase Realtime Database
    // Example code:
    _setIdFromPreference();
    _loadData();
  }
  void _setIdFromPreference() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getString('createdAt') ?? '';
    });
  }
  Future<void> _loadData() async {
    FirebaseDatabase.instance
        .ref()
        .child(id)
        .child('upi_accounts')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _upiAccounts = data.entries
              .map((e) =>
                  UPIDetails.fromMap(Map<String, dynamic>.from(e.value as Map)))
              .toList();
        });
      }
    });
    //
    FirebaseDatabase.instance
        .ref()
        .child(id)
        .child('payment_settings')
        .child('accept_upi')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as bool?;
      if (data != null) {
        setState(() {
          _acceptUPI = data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment Settings'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master switch for UPI
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: Colors.blue, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accept UPI Payments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Enable UPI payments for your customers',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _acceptUPI,
                  onChanged: (value) {
                    setState(() {
                      _acceptUPI = value;
                    });

                    // TODO: Update Firebase Realtime Database
                    // Example code:
                    FirebaseDatabase.instance
                        .ref()
                        .child(id)
                        .child('payment_settings')
                        .child('accept_upi')
                        .set(value);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),

          if (_acceptUPI) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Your UPI Accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: _upiAccounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No UPI accounts added yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your UPI ID to start accepting payments',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addUPIAccount,
                            icon: const Icon(Icons.add),
                            label: const Text('Add UPI Account'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _upiAccounts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final account = _upiAccounts[index];
                        return UPIAccountItem(
                          upiDetails: account,
                          onEdit: () => _editUPIAccount(account),
                          onDelete: () => _deleteUPIAccount(account.id),
                          onToggle: () => _toggleUPIAccountStatus(account.id),
                          onSetPrimary: account.isPrimary
                              ? null
                              : () => _setPrimaryUPIAccount(account.id),
                        );
                      },
                    ),
            ),
          ],

          if (!_acceptUPI)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 72,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'UPI Payments are disabled',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable UPI payments using the switch above',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _acceptUPI
          ? FloatingActionButton(
              onPressed: _addUPIAccount,
              child: const Icon(Icons.add),
              tooltip: 'Add new UPI account',
            )
          : null,
    );
  }
}

class UPIAccountItem extends StatelessWidget {
  final UPIDetails upiDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback? onSetPrimary;

  const UPIAccountItem({
    Key? key,
    required this.upiDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    this.onSetPrimary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shadowColor:
          upiDetails.isPrimary ? Colors.blue.withOpacity(0.4) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: upiDetails.isPrimary
              ? Colors.blue.shade300
              : (upiDetails.isActive
                  ? Colors.green.shade100
                  : Colors.grey.shade200),
          width: upiDetails.isPrimary ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: upiDetails.isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.blue.shade50],
                )
              : null,
        ),
        child: Column(
          children: [
            // UPI details section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UPI App icon with badge for primary
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: upiDetails.isActive
                              ? (upiDetails.isPrimary
                                  ? Colors.blue.shade100
                                  : Colors.blue.shade50)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: upiDetails.isActive && upiDetails.isPrimary
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          _getIconForUPIApp(upiDetails.upiApp),
                          color: upiDetails.isActive
                              ? (upiDetails.isPrimary
                                  ? Colors.blue.shade800
                                  : Colors.blue.shade600)
                              : Colors.grey,
                          size: 26,
                        ),
                      ),
                      if (upiDetails.isPrimary)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // UPI Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                upiDetails.upiId,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: upiDetails.isActive
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Status switch - moved to right side for better UX
                            Switch.adaptive(
                              value: upiDetails.isActive,
                              onChanged: (_) => onToggle(),
                              activeColor: Colors.green,
                              activeTrackColor: Colors.green.shade100,
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade200,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Merchant name and bank
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upiDetails.merchantName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: upiDetails.isActive
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (upiDetails.bankName != null)
                                    Text(
                                      upiDetails.bankName!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: upiDetails.isActive
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Primary badge - shown on larger screens inline
                            if (upiDetails.isPrimary && !isSmallScreen)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: const Text(
                                  'Primary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

            // Actions section - Responsive layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool useCompactLayout = constraints.maxWidth < 400;

                  // For small screens, use a more compact layout with icons
                  if (useCompactLayout) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (onSetPrimary != null)
                          _buildIconButton(
                            Icons.star_outline,
                            'Primary',
                            Colors.amber[700] ?? Colors.amber,
                            onSetPrimary!,
                          ),
                        _buildIconButton(
                          Icons.qr_code,
                          'QR',
                          Colors.purple,
                          () => _showQRCode(context),
                        ),
                        _buildIconButton(
                          Icons.edit_outlined,
                          'Edit',
                          Colors.blue,
                          onEdit,
                        ),
                        _buildIconButton(
                          Icons.delete_outline,
                          'Delete',
                          Colors.red,
                          onDelete,
                        ),
                      ],
                    );
                  }

                  // For larger screens, use text buttons
                  return Row(
                    children: [
                      if (onSetPrimary != null)
                        TextButton.icon(
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: const Text('Set Primary'),
                          onPressed: onSetPrimary,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber[700],
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('Show QR'),
                        onPressed: () => _showQRCode(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for compact icon buttons
  Widget _buildIconButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show QR code dialog
  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan to Pay',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                upiDetails.upiId,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code,
                          size: 80, color: Colors.blue.shade800),
                      const SizedBox(height: 16),
                      Text(
                        'QR Code for\n${upiDetails.upiId}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForUPIApp(String? app) {
    if (app == null) return Icons.account_balance_wallet_outlined;

    switch (app.toLowerCase()) {
      case 'google pay':
        return Icons.g_mobiledata;
      case 'phonepe':
        return Icons.phone_android;
      case 'paytm':
        return Icons.account_balance_wallet;
      case 'bhim':
        return Icons.payments_outlined;
      case 'amazon pay':
        return Icons.shopping_cart_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

// QR Code Dialog
class UPIQRCodeDialog extends StatelessWidget {
  final String upiId;

  const UPIQRCodeDialog({Key? key, required this.upiId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan to Pay',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              upiId,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            // Placeholder for QR Code - In a real app, use a QR code generation library
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code, size: 80),
                    const SizedBox(height: 16),
                    Text(
                      'QR Code for\n$upiId',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for adding/editing UPI accounts
class AddEditUPIDialog extends StatefulWidget {
  final UPIDetails? upiDetails;

  const AddEditUPIDialog({
    Key? key,
    this.upiDetails,
  }) : super(key: key);

  @override
  State<AddEditUPIDialog> createState() => _AddEditUPIDialogState();
}

class _AddEditUPIDialogState extends State<AddEditUPIDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _upiIdController;
  late TextEditingController _merchantNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _bankNameController;
  bool _isActive = true;
  bool _isPrimary = false;
  String _selectedUpiApp = 'Google Pay';

  final List<String> _upiApps = [
    'Google Pay',
    'PhonePe',
    'Paytm',
    'BHIM',
    'Amazon Pay',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final account = widget.upiDetails;
    _upiIdController = TextEditingController(text: account?.upiId ?? '');
    _merchantNameController =
        TextEditingController(text: account?.merchantName ?? '');
    _displayNameController =
        TextEditingController(text: account?.displayName ?? '');
    _bankNameController = TextEditingController(text: account?.bankName ?? '');
    _isActive = account?.isActive ?? true;
    _isPrimary = account?.isPrimary ?? false;
    _selectedUpiApp = account?.upiApp ?? 'Google Pay';
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _merchantNameController.dispose();
    _displayNameController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _saveUPIAccount() {
    if (_formKey.currentState!.validate()) {
      final account = UPIDetails(
        id: widget.upiDetails?.id ?? const Uuid().v4(),
        upiId: _upiIdController.text,
        merchantName: _merchantNameController.text,
        displayName: _displayNameController.text.isEmpty
            ? null
            : _displayNameController.text,
        isPrimary: _isPrimary,
        isActive: _isActive,
        bankName:
            _bankNameController.text.isEmpty ? null : _bankNameController.text,
        upiApp: _selectedUpiApp,
      );

      Navigator.of(context).pop(account);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.upiDetails != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit UPI Account' : 'Add UPI Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _upiIdController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'e.g. yourname@okbank, phone@upi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your UPI ID';
                  }
                  if (!value.contains('@')) {
                    return 'UPI ID must contain @ symbol';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _merchantNameController,
                decoration: const InputDecoration(
                  labelText: 'Merchant Name',
                  hintText: 'Name that appears during payment',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter merchant name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name (Optional)',
                  hintText: 'Name displayed in your app',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name (Optional)',
                  hintText: 'e.g. SBI, HDFC, ICICI',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'UPI App:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUpiApp,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: _upiApps.map((app) {
                  return DropdownMenuItem<String>(
                    value: app,
                    child: Text(app),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedUpiApp = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Primary Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isPrimary,
                    onChanged: (value) {
                      setState(() {
                        _isPrimary = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Active',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveUPIAccount,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
