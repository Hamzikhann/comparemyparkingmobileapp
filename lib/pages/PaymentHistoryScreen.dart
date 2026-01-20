import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/models/PaymentResponse.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:parkingapp/pages/ReceiptScreen.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:parkingapp/services/notification_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<PaymentResponse> _futurePayments;
  final GeneralRepository _repository = GeneralRepository();
  final String title = "Payment History"; // Title for TopBar

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  void _loadPaymentHistory() {
    setState(() {
      _futurePayments = _repository.getPaymentHistory().catchError((error) {
        return PaymentResponse(message: 'Error', payments: []);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: title,
              showBackButton: false,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadPaymentHistory();
                },
                child: FutureBuilder<PaymentResponse>(
                  future: _futurePayments,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center();
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load payments',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPaymentHistory,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData ||
                        snapshot.data!.payments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No payment history found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your payment history will appear here',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: snapshot.data!.payments.length,
                        itemBuilder: (context, index) {
                          final payment = snapshot.data!.payments[index];
                          return _buildPaymentCard(context, payment);
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(payment: payment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Airport: ${payment.booking.airport}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.booking.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.booking.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dates: ${payment.booking.startDate} to ${payment.booking.endDate}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Method',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.paymentMethod,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reference No',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.referenceNo,
                        style: const TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '£${payment.totalPayment}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.secondarynew,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid on: ${_formatDate(payment.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded,
                        color: colors.secondarynew),
                    onPressed: () => _downloadPaymentPdf(payment),
                    tooltip: 'Download PDF',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return colors.secondarynew;
      case 'inprogress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getDurationString(Payment payment) {
    try {
      final start = DateTime.parse(
          "${payment.booking.startDate} ${payment.booking.startTime}");
      final end = DateTime.parse(
          "${payment.booking.endDate} ${payment.booking.endTime}");
      final days = end.difference(start).inDays;
      if (days == 0) return "1 Day";
      return "$days Days";
    } catch (e) {
      return "N/A";
    }
  }

  Future<void> _downloadPaymentPdf(Payment payment) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied")),
          );
          return;
        }
      }

      // Load logo image
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo at the top
                pw.Center(
                  child: pw.Image(logoImage, width: 150, height: 50),
                ),
                pw.SizedBox(height: 20),

                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#4B725D'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Payment Receipt',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '£${payment.totalPayment}',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _formatDate(payment.createdAt),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Details
                pw.Text(
                  'Transaction Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfRow('Reference ID', payment.referenceNo),
                _buildPdfRow('Payment Method', payment.paymentMethod),
                _buildPdfRow('Status', 'Completed'),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Booking Details
                pw.Text(
                  'Booking Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfRow('Service', 'Car Parking'),
                _buildPdfRow('Airport', payment.booking.airport),
                _buildPdfRow('Duration', _getDurationString(payment)),
                _buildPdfRow('Start Date', payment.booking.startDate),
                _buildPdfRow('End Date', payment.booking.endDate),
                pw.SizedBox(height: 20),

                // Total
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8F9FA'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Paid',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '£${payment.totalPayment}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory!.path}/receipt_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      // Show notification
      await NotificationService().showDownloadNotification(
        filePath: file.path,
        title: 'Receipt Downloaded',
        body: 'Receipt downloaded successfully',
      );

      // Auto-open the PDF
      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded to: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error downloading PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download PDF: $e")),
        );
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
