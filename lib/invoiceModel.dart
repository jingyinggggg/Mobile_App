import 'package:assignment_tripmate/customerModel.dart';
import 'package:assignment_tripmate/supplierModel.dart';

class Invoice {
  final InvoiceInfo info;
  final Supplier supplier;
  final Customer customer;
  final List<InvoiceItem> items;

  const Invoice({
    required this.info,
    required this.supplier,
    required this.customer,
    required this.items,
  });
}

class InvoiceInfo {
  final String description;
  final String number;
  final DateTime date;

  const InvoiceInfo({
    required this.description,
    required this.number,
    required this.date,
  });
}

class InvoiceItem {
  final String description;
  // final String date;
  final int quantity;
  final int unitPrice;
  final double total;

  const InvoiceItem({
    required this.description,
    // required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.total
  });
}