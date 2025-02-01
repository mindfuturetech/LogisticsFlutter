// widgets/report_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/model/truck_details_model.dart';

class ReportCard extends StatelessWidget {
  final TripDetails report;

  const ReportCard({
    Key? key,
    required this.report,
  }) : super(key: key);

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, Map<String, String?> document) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              // Implement document download/view logic here
            },
            icon: const Icon(Icons.file_download),
            label: Text(document['originalname'] ?? 'Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text('${report.truckNumber} - ${report.doNumber}'),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt!),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Driver', report.driverName),
                _buildInfoRow('Vendor', report.vendor),
                _buildInfoRow('From', report.destinationFrom),
                _buildInfoRow('To', report.destinationTo),
                _buildInfoRow('Status', report.transactionStatus),
                _buildInfoRow('Weight', '${report.weight} kg'),
                _buildInfoRow('Actual Weight', '${report.actualWeight} kg'),
                _buildInfoRow('Difference', '${report.differenceInWeight} kg'),
                _buildInfoRow('Freight', '₹${report.freight}'),
                _buildInfoRow('Diesel', '${report.diesel} L'),
                _buildInfoRow('Diesel Amount', '₹${report.dieselAmount}'),
                _buildInfoRow('TDS Rate', '${report.tdsRate}%'),
                _buildInfoRow('Advance', '₹${report.advance}'),
                if (report.dieselSlipImage?.isNotEmpty ?? false)
                  _buildDocumentRow('Diesel Slip', report.dieselSlipImage!),
                if (report.loadingAdvice?.isNotEmpty ?? false)
                  _buildDocumentRow('Loading Advice', report.loadingAdvice!),
                if (report.invoiceCompany?.isNotEmpty ?? false)
                  _buildDocumentRow('Invoice', report.invoiceCompany!),
                if (report.weightmentSlip?.isNotEmpty ?? false)
                  _buildDocumentRow('Weightment Slip', report.weightmentSlip!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}