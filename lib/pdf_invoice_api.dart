import 'dart:io';
import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/customerModel.dart';
import 'package:assignment_tripmate/invoiceModel.dart';
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'supplierModel.dart';

class PdfInvoiceApi {
  static Future<void> openFile(File file) async {
    await OpenFile.open(file.path);
  }

  static Future<File> generate(
    Invoice invoice,
    String userID,
    String bookingID,
    String servicesType,
    String collectionName,
    String pdfName,
    bool isDeposit,
    bool isRefund,
    bool isDepositRefund
  ) async {
    final pdf = Document();

    // Add content to the PDF
    pdf.addPage(MultiPage(
      build: (context) => [
        buildHeader(invoice),
        SizedBox(height: 3 * PdfPageFormat.cm),
        buildTitle(invoice),
        buildInvoice(invoice, servicesType),
        Divider(),
        buildTotal(invoice.items),
      ],
      footer: (context) => buildFooter(),
    ));

    // Get the system's temporary directory
    final directory = await getTemporaryDirectory();

    // Create a temporary file for the PDF
    final tempPdfFile = File('${directory.path}/$pdfName.pdf');

    // Write the PDF data to the temporary file only once
    final pdfData = await pdf.save();
    await tempPdfFile.writeAsBytes(pdfData);

    final storeData = StoreData();

    // Save the invoice by uploading the file to Firebase Storage
    await storeData.saveInvoice(
      userID: userID,
      bookingID: bookingID,
      servicesType: servicesType,
      collectionName: collectionName,
      pdfName: pdfName,
      pdf: tempPdfFile,
      isDeposit: isDeposit,
      isRefund: isRefund,
      isDepositRefund: isDepositRefund
    );

    return tempPdfFile;
  }

  static Widget buildHeader(Invoice invoice) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 1 * PdfPageFormat.cm),
      Text(
        "TripMate",
        style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold)
      ),
      SizedBox(height: 10),
      Text(
        "Provider: ",
        style: TextStyle(fontWeight: FontWeight.bold)
      ),
      SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Use Expanded to ensure the supplier address respects the flex
          Expanded(
            flex: 5,
            child: buildSupplierAddress(invoice.supplier),
          ),
          // Use Expanded for the QR code as well to control its size within the layout
          Expanded(
            flex: 2,  // Adjust the flex value to better control the QR code's space
            child: Align(
              alignment: Alignment.centerRight,
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: invoice.info.number,
                width: 50,  // You can still define a size within the Expanded widget
                height: 50,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 1 * PdfPageFormat.cm),
      Text(
        "Customer: ",
        style: TextStyle(fontWeight: FontWeight.bold)
      ),
      SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(flex: 6, child: buildCustomerAddress(invoice.customer)),
          Expanded(flex: 4, child: buildInvoiceInfo(invoice.info)),
        ],
      ),
    ],
  );

  static Widget buildCustomerAddress(Customer customer) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(customer.name, style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Text(customer.address, overflow: TextOverflow.visible, maxLines: 3, style: TextStyle(lineSpacing: 1.5)),
    ],
  );

  static Widget buildSupplierAddress(Supplier supplier) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(supplier.name, style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Text(supplier.address, style: TextStyle(lineSpacing: 1.5)),
    ],
  );

  static Widget buildInvoiceInfo(InvoiceInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 85,  // Fixed width for label
              child: Text('Invoice Number'),
            ),
            SizedBox(width: 5),
            Text(':'),
            SizedBox(width: 5),
            Expanded(  // Expands the space for the invoice number
              child: Text(
                info.number,
                textAlign: TextAlign.right,  // Align text to the left
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Container(
              width: 85,  // Fixed width for label
              child: Text('Invoice Date'),
            ),
            SizedBox(width: 5),
            Text(':'),
            SizedBox(width: 10),
            Expanded(  // Expands the space for the invoice date
              child: Text(
                formatDate(info.date),
                textAlign: TextAlign.right,  // Align text to the left
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildTitle(Invoice invoice) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('INVOICE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 0.4 * PdfPageFormat.cm),
      Text(invoice.info.description),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
    ],
  );

  static Widget buildInvoice(Invoice invoice, String servicesType) {
    final header = ['Description', 'Quantity', 'Unit Price (RM)', 'Total (RM)'];

    // Create a list of rows by mapping each item in the invoice.items list
    final data = invoice.items.map((item) {
      return [
        "${item.description}",
        item.quantity.toString(),
        '${NumberFormat('#,##0.00').format(item.unitPrice)}',
        '${NumberFormat('#,##0.00').format(item.total)}',
      ];
    }).toList();

    return TableHelper.fromTextArray(
      headers: header,
      data: data,  // Use the data list we just created
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold),
      headerDecoration: BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerRight,
        2: Alignment.centerRight,
        3: Alignment.centerRight,
      },
      columnWidths: {
        0: FractionColumnWidth(0.5),
        1: FractionColumnWidth(0.15),
        2: FractionColumnWidth(0.2),
        3: FractionColumnWidth(0.15),
      },
    );
  }


  static Widget buildTotal(List<InvoiceItem> items) {
    // Calculate the total amount by summing the total of all items
    final totalAmount = items.fold<double>(
      0, (previousValue, item) => previousValue + item.total);

    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Spacer(flex: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildText(
                  title: 'Net total',
                  value: formatPrice(totalAmount),  // Use the new price format function
                  unite: true
                ),
                Divider(),
                buildText(
                  title: 'Total amount',
                  titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  value: formatPrice(totalAmount),  // Same format for total amount
                  unite: true
                ),
                SizedBox(height: 2 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
                SizedBox(height: 0.5 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFooter() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Divider(),
      SizedBox(height: 2 * PdfPageFormat.mm),
      Text(
        'This is the computer generated document which does not require any signature.',
        style: TextStyle(fontWeight: FontWeight.bold)
      ),
    ],
  );

  static buildSimpleText({required String title, required String value}) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(value),
      ],
    );
  }

  static buildText({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: unite ? style : null),
        ],
      ),
    );
  }

  static String formatPrice(double price) => '\RM ${NumberFormat('#,##0.00').format(price)}';
  static String formatDate(DateTime date) => DateFormat('d MMM y').format(date);
}
