import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/widgets/driver/TopBar.dart';
import '../../data/models/Payment.dart';

class PaymentScreenAdmin extends StatefulWidget {
  const PaymentScreenAdmin({Key? key}) : super(key: key);

  @override
  State<PaymentScreenAdmin> createState() => _PaymentScreenAdminState();
}

class _PaymentScreenAdminState extends State<PaymentScreenAdmin> {
  List<Payment> _payments = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
    });

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final url = Uri.parse('http://137.184.9.55:8000/api/payment/v2/list');

    try {
      final response = await http.post(
        url,
        headers: {
          'access-token': Globals.user?.token ?? '',
          'Content-Type': 'application/json',
        },
        body: json.encode({'startDate': formattedDate}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body['data'] != null && body['data'] is List) {
          final List<dynamic> paymentsJson = body['data'];
          setState(() {
            _payments = paymentsJson.map((json) => Payment.fromJson(json)).toList();
          });
        } else {
          setState(() {
            _payments = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No payments found.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payments. Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _fetchPayments();
    }
  }

  void _moveDate(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    if (newDate.isAfter(DateTime.now())) return;
    setState(() {
      _selectedDate = newDate;
    });
    _fetchPayments();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'inprogress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.booking.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.booking.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dates: ${payment.booking.startDate} to ${payment.booking.endDate}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('Method', payment.paymentMethod),
                  _buildInfoColumn('Reference No', payment.referenceNo),
                  _buildInfoColumn('Payment', '£${payment.totalPayment}', highlight: true),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Paid',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 16 : 10,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( // <-- This fixes both issues
        child: Column(
          children: [
            TopBar(
              title: 'Payments',
              onBackPressed: () => Navigator.pop(context),
              showBackButton: true,
              onLogoutPressed: () {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _moveDate(-1),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _selectDate,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                              ? 'Today'
                              : DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                        ? null
                        : () => _moveDate(1),
                    icon: const Icon(Icons.arrow_forward),
                    color: DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                        ? Colors.grey
                        : Colors.black,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _payments.isEmpty
                      ? const Center(child: Text('No payments found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            return _buildPaymentCard(_payments[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
