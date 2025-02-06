// todays_list_screen.dart
import 'package:flutter/material.dart';
import 'package:logistics/screens/auth/report_card_screen.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';
import './home_screen.dart'; // Add this import

class TodaysListScreen extends StatefulWidget {
  const TodaysListScreen({Key? key}) : super(key: key);

  @override
  _TodaysListScreenState createState() => _TodaysListScreenState();
}

class _TodaysListScreenState extends State<TodaysListScreen> {
  final ReportsService _reportsService = ReportsService();
  List<TripDetails> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayReports();
  }

  // Add this method to handle navigation to home screen
  void _navigateToHomeScreen(TripDetails? tripDetails) {
    if (tripDetails != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TruckDetailsScreen(
            initialTripDetails: tripDetails,
            username: tripDetails.username,
          ),
        ),
      );
    }
  }

  Future<void> _fetchTodayReports() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reports = await _reportsService.getReports(
        startDate: today,
        endDate: today,
      );
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to fetch today\'s reports');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchTodayReports();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReportsList(),
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return const Center(child: Text('No reports found for today'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return ReportCard(
          report: report,
          onTripFound: _navigateToHomeScreen, // Add this callback
        );
      },
    );
  }
}