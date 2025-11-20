import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_3/create_order_dialog.dart';
import 'package:flutter_application_3/edit_order_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_application_3/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderFormTab extends StatefulWidget {
  const OrderFormTab({super.key});

  @override
  State<OrderFormTab> createState() => _OrderFormTabState();
}

class _OrderFormTabState extends State<OrderFormTab> {
  final SupabaseClient supabase = Supabase.instance.client;
  late TextEditingController _searchController;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _viewFile(BuildContext context, String fileUrl) async {
    try {
      final supabase = Supabase.instance.client;

      // Determine the file path within the bucket
      String bucketPath;
      if (fileUrl.contains('/storage/v1/object/public/OrderForm/')) {
        final uri = Uri.parse(fileUrl);
        bucketPath = uri.path.split('/').skip(6).join('/');
      } else {
        bucketPath = fileUrl;
      }

      // Try to get a public URL first
      final publicUrl = supabase.storage
          .from('OrderForm')
          .getPublicUrl(bucketPath);

      // Test if the public URL works by making a quick HEAD request
      final response = await http.head(Uri.parse(publicUrl));

      String fileToOpen;

      if (response.statusCode == 200) {
        // Public URL works fine — use it
        fileToOpen = publicUrl;
      } else {
        // Public URL is not accessible — create a signed URL valid for 60 seconds
        final signedResponse = await supabase.storage
            .from('OrderForm')
            .createSignedUrl(bucketPath, 60);
        fileToOpen = signedResponse;
      }

      // Open the URL
      final uri = Uri.parse(fileToOpen);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open file')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error viewing file: $e')));
      }
    }
  }

  void _showEditOrderSheet(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditOrderDialog(
          order: order,
          onOrderUpdated: (updatedOrder) {
            _fetchOrders();
          },
        );
      },
    );
  }

  Future<void> _downloadFile(BuildContext context, String fileUrl) async {
    try {
      final supabase = Supabase.instance.client;
      String bucketPath;
      if (fileUrl.contains('/storage/v1/object/public/OrderForm/')) {
        final uri = Uri.parse(fileUrl);
        bucketPath = uri.path
            .split('/')
            .skip(6)
            .join('/'); // Skips /storage/v1/object/public/OrderForm/
      } else {
        bucketPath = fileUrl;
      }
      final fileName = p.basename(fileUrl);
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        final signedUrl = await supabase.storage
            .from('OrderForm')
            .createSignedUrl(bucketPath, 600);
        final uri = Uri.parse(signedUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading via browser')),
          );
        }
      } else {
        final data = await supabase.storage
            .from('OrderForm')
            .download(bucketPath);
        final prefs = await SharedPreferences.getInstance();
        final prefPath = prefs.getString('download_path');
        Directory targetDir;
        if (prefPath != null && prefPath.isNotEmpty) {
          targetDir = Directory(prefPath);
          if (!targetDir.existsSync()) {
            targetDir.createSync(recursive: true);
          }
        } else {
          Directory? downloadsDir;
          try {
            downloadsDir = await getDownloadsDirectory();
          } catch (_) {}
          targetDir = downloadsDir ?? await getApplicationDocumentsDirectory();
          if (!targetDir.existsSync()) {
            targetDir.createSync(recursive: true);
          }
        }
        final file = File('${targetDir.path}/$fileName');
        await file.writeAsBytes(data);
        final uri = Uri.file(file.path);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
      }
    }
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in.';
          _isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Order> fetchedOrders = (response as List).map((order) {
        final files = order['order_files'];
        List<String> parsedFiles = [];

        if (files is List) {
          parsedFiles = files.map((f) => f.toString()).toList();
        } else if (files is String) {
          parsedFiles = [files];
        }

        return Order(
          id: order['id']?.toString() ?? '',
          customerName: order['customer_name']?.toString() ?? '',
          dentalTechnicianName: order['technician_name']?.toString() ?? '',
          toothColor: order['tooth_color']?.toString() ?? '',
          selectedTeeth: (order['selected_teeth'] is List)
              ? List<int>.from(order['selected_teeth'])
              : [],
          orderDetails: order['details']?.toString() ?? '',
          orderFiles: parsedFiles,
          createdAt: order['created_at']?.toString() ?? '',
        );
      }).toList();

      setState(() {
        _orders = fetchedOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteOrder(String orderId, String customerName) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delete Order?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF020817),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete the order for $customerName? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('orders').delete().eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Order deleted successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      await _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error deleting order: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showCreateOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CreateOrderDialog(
          onOrderCreated: (order) {
            _fetchOrders();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Color(0xFF16A34A),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Order Forms',
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF020817),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: _fetchOrders,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create and manage dental order forms with detailed specifications',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search orders...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF94A3B8),
                            size: 22,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showCreateOrderSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'New Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
            const SizedBox(height: 20),

            // Order List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFEF4444),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No orders yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF020817),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first order to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        0,
                        isMobile ? 16 : 24,
                        isMobile ? 16 : 24,
                      ),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];

                        if (_searchController.text.isNotEmpty &&
                            !order.customerName.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            )) {
                          return const SizedBox.shrink();
                        }

                        return OrderCard(
                          order: order,
                          isMobile: isMobile,
                          onDelete: () =>
                              _deleteOrder(order.id, order.customerName),
                          onDownload: _downloadFile,
                          onView: _viewFile,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Order {
  final String id;
  final String customerName;
  final String dentalTechnicianName;
  final String toothColor;
  final List<int> selectedTeeth;
  final String orderDetails;
  final List<String> orderFiles;
  final String createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.dentalTechnicianName,
    required this.toothColor,
    required this.selectedTeeth,
    required this.orderDetails,
    required this.orderFiles,
    required this.createdAt,
  });
}

class OrderCard extends StatelessWidget {
  final Order order;
  final bool isMobile;
  final VoidCallback onDelete;
  final Future<void> Function(BuildContext, String) onDownload;
  final Future<void> Function(BuildContext, String) onView;

  const OrderCard({
    super.key,
    required this.order,
    this.isMobile = false,
    required this.onDelete,
    required this.onDownload,
    required this.onView,
  });

  Widget _buildFileChip(BuildContext context, String fileUrl) {
    final fileName = Uri.parse(fileUrl).pathSegments.last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_rounded,
            size: 16,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF020817),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => onView(context, fileUrl),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.visibility_rounded,
                size: 14,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => onDownload(context, fileUrl),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.download_rounded,
                size: 14,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF020817),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.dentalTechnicianName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.createdAt.split("T").first,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
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
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return EditOrderDialog(
                                order: order,
                                onOrderUpdated: (updates) {
                                  // Refresh your orders list or update the order locally
                                  (context
                                      .findAncestorStateOfType<
                                        _OrderFormTabState
                                      >()
                                    ?.._fetchOrders());
                                },
                              );
                            },
                          );
                        },
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        onPressed: onDelete,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tooth Color
            Row(
              children: [
                const Text(
                  'Tooth Color:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.toothColor,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Selected Teeth
            const Text(
              'Selected Teeth:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: order.selectedTeeth
                  .map(
                    (tooth) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '$tooth',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF020817),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Details
            const Text(
              'Details:',
              style: TextStyle(
                fontSize: 13, // Added a default font size
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                order.orderDetails,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF020817),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Files
            const Text(
              'Files:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              children: order.orderFiles
                  .map((file) => _buildFileChip(context, file))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
