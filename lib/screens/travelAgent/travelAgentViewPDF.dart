import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TravelAgentViewPDFScreen extends StatefulWidget {
  final String pdfPath;
  final bool savedToFirebase;

  const TravelAgentViewPDFScreen({super.key, required this.pdfPath, required this.savedToFirebase});

  @override
  State<TravelAgentViewPDFScreen> createState() => _TravelAgentViewPDFScreenState();
}

class _TravelAgentViewPDFScreenState extends State<TravelAgentViewPDFScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("PDF View"),
        centerTitle: true,
        backgroundColor: const Color(0xFF749CB9),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inika',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ],
      ),
      body: widget.savedToFirebase == true
          ? SfPdfViewer.network(
              widget.pdfPath,
            )
          : SfPdfViewer.file(
              File(widget.pdfPath), // Assuming widget.pdfPath is the local file path
            ),
    );
  }
}