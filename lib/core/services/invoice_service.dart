import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/sales_vehicles/model/sale_model.dart';
import '../../features/sales_vehicles/model/vehicle_model.dart';
import '../../features/sales_vehicles/model/vehicle_status.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/invoice_dialog.dart';

/// Structured data model representing an invoice for a vehicle sale.
class InvoiceData {
  final String invoiceNumber;
  final String invoiceDate;
  final String customerName;
  final String customerPhone;
  final String vehicleNumber;
  final String vehicleName;
  final String vehicleModel;
  final String vehicleType;
  final int manufacturingYear;
  final int registrationYear;
  final double salePrice;
  final double documentCharges;
  final double totalAmount;
  final double totalPaid;
  final double balance;
  final String paymentType;
  final bool isEmi;
  final String? financeName;
  final String? notes;

  InvoiceData({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleNumber,
    required this.vehicleName,
    required this.vehicleModel,
    required this.vehicleType,
    required this.manufacturingYear,
    required this.registrationYear,
    required this.salePrice,
    required this.documentCharges,
    required this.totalAmount,
    required this.totalPaid,
    required this.balance,
    required this.paymentType,
    required this.isEmi,
    this.financeName,
    this.notes,
  });

  /// Factory to construct [InvoiceData] strictly from completed vehicle & sale records.
  factory InvoiceData.fromVehicleAndSale({
    required VehicleModel vehicle,
    required VehicleSaleModel sale,
    double? totalPaid,
    double? balance,
  }) {
    final cleanReg = vehicle.vehicleNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final dateStr = sale.saleDate.replaceAll('-', '').replaceAll('/', '');
    final prefix = dateStr.length >= 8 ? dateStr.substring(0, 8) : dateStr;
    final invNum = 'INV-$prefix-$cleanReg';

    final effectiveTotal = sale.totalAmount + sale.documentCharges;
    final effectivePaid = totalPaid ?? effectiveTotal;
    final effectiveBalance = balance ?? 0.0;

    return InvoiceData(
      invoiceNumber: invNum,
      invoiceDate: sale.saleDate,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      vehicleNumber: vehicle.vehicleNumber,
      vehicleName: vehicle.vehicleName,
      vehicleModel: vehicle.vehicleModel,
      vehicleType: vehicle.vehicleType.displayName,
      manufacturingYear: vehicle.manufacturingYear,
      registrationYear: vehicle.registrationYear,
      salePrice: sale.totalAmount,
      documentCharges: sale.documentCharges,
      totalAmount: effectiveTotal,
      totalPaid: effectivePaid,
      balance: effectiveBalance,
      paymentType: sale.paymentType.displayName,
      isEmi: sale.isEmi,
      financeName: sale.financeName,
      notes: sale.notes,
    );
  }
}

/// Service handling invoice generation, HTML rendering, browser preview, and file export.
class InvoiceService {
  /// Generate print-ready professional HTML invoice.
  String buildHtmlInvoice(InvoiceData data) {
    final formattedSalePrice = CurrencyUtils.format(data.salePrice);
    final formattedDocCharges = CurrencyUtils.format(data.documentCharges);
    final formattedTotal = CurrencyUtils.format(data.totalAmount);
    final formattedPaid = CurrencyUtils.format(data.totalPaid);
    final formattedBalance = CurrencyUtils.format(data.balance);
    final displayDate = AppDateUtils.formatDisplay(data.invoiceDate);

    final paymentDisplay = data.isEmi && data.financeName != null && data.financeName!.isNotEmpty
        ? '${data.paymentType} (${data.financeName})'
        : data.paymentType;

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice - ${data.invoiceNumber}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: #f1f5f9;
      color: #1e293b;
      padding: 30px 15px;
    }
    .no-print-bar {
      max-width: 820px;
      margin: 0 auto 16px auto;
      display: flex;
      justify-content: flex-end;
      gap: 12px;
    }
    .print-btn {
      background: #2563eb;
      color: #ffffff;
      border: none;
      padding: 10px 20px;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      box-shadow: 0 2px 6px rgba(37,99,235,0.3);
      transition: background 0.2s;
    }
    .print-btn:hover { background: #1d4ed8; }
    .invoice-card {
      max-width: 820px;
      margin: 0 auto;
      background: #ffffff;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.06);
      padding: 44px;
      border: 1px solid #e2e8f0;
    }
    .header-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 2px solid #e2e8f0;
      padding-bottom: 24px;
    }
    .brand-title {
      font-size: 26px;
      font-weight: 800;
      color: #0f172a;
      letter-spacing: -0.5px;
    }
    .brand-sub {
      font-size: 13px;
      color: #64748b;
      margin-top: 4px;
      font-weight: 500;
    }
    .invoice-badge-block {
      text-align: right;
    }
    .invoice-badge-title {
      font-size: 22px;
      font-weight: 800;
      color: #2563eb;
      letter-spacing: 0.5px;
    }
    .invoice-meta {
      font-size: 13px;
      color: #64748b;
      margin-top: 4px;
    }
    .status-badge {
      display: inline-block;
      background: #dcfce7;
      color: #166534;
      font-size: 11px;
      font-weight: 700;
      padding: 4px 12px;
      border-radius: 20px;
      margin-top: 8px;
      border: 1px solid #86efac;
    }
    .grid-section {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 32px;
      margin-top: 28px;
      padding-bottom: 28px;
      border-bottom: 1px solid #e2e8f0;
    }
    .section-title {
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      color: #64748b;
      margin-bottom: 10px;
    }
    .info-row {
      display: flex;
      margin-bottom: 6px;
      font-size: 14px;
    }
    .info-label {
      width: 120px;
      color: #64748b;
      font-weight: 500;
    }
    .info-value {
      flex: 1;
      color: #0f172a;
      font-weight: 600;
    }
    .plate-badge {
      display: inline-block;
      background: #f1f5f9;
      padding: 3px 8px;
      border-radius: 6px;
      border: 1px solid #cbd5e1;
      font-family: monospace;
      font-weight: 700;
      color: #0f172a;
    }
    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 28px;
    }
    .items-table th {
      background: #f8fafc;
      padding: 12px 16px;
      text-align: left;
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      color: #475569;
      border-bottom: 2px solid #e2e8f0;
    }
    .items-table td {
      padding: 14px 16px;
      border-bottom: 1px solid #f1f5f9;
      font-size: 14px;
      color: #1e293b;
    }
    .text-right { text-align: right !important; }
    .totals-wrapper {
      display: flex;
      justify-content: flex-end;
      margin-top: 20px;
    }
    .totals-table {
      width: 320px;
      border-collapse: collapse;
    }
    .totals-table td {
      padding: 7px 0;
      font-size: 14px;
    }
    .totals-table .label { color: #64748b; }
    .totals-table .val { text-align: right; font-weight: 600; color: #0f172a; }
    .grand-total-row td {
      border-top: 2px solid #e2e8f0;
      padding-top: 12px;
      font-size: 16px;
      font-weight: 800;
      color: #0f172a;
    }
    .settlement-badge {
      margin-top: 24px;
      padding: 12px 16px;
      background: #f0fdf4;
      border: 1px solid #bbf7d0;
      border-radius: 8px;
      font-size: 13px;
      color: #166534;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .signatures-block {
      margin-top: 60px;
      display: flex;
      justify-content: space-between;
    }
    .sign-card {
      width: 240px;
      border-top: 1px dashed #94a3b8;
      text-align: center;
      padding-top: 8px;
      font-size: 13px;
      color: #64748b;
    }
    @media print {
      body { background: #ffffff; padding: 0; }
      .no-print-bar { display: none; }
      .invoice-card { box-shadow: none; border: none; padding: 24px; }
    }
  </style>
</head>
<body>
  <div class="no-print-bar">
    <button class="print-btn" onclick="window.print()">
      <svg width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
        <path d="M2.5 8a.5.5 0 1 0 0-1 .5.5 0 0 0 0 1z"/>
        <path d="M5 1a2 2 0 0 0-2 2v2H2a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h1v1a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-1h1a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-1V3a2 2 0 0 0-2-2H5zM4 3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2H4V3zm1 5a2 2 0 0 0-2 2v1H2a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-1v-1a2 2 0 0 0-2-2H5zm7 2v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1z"/>
      </svg>
      Print / Save as PDF
    </button>
  </div>

  <div class="invoice-card">
    <div class="header-row">
      <div>
        <div class="brand-title">VEHICLE CONSULTING</div>
        <div class="brand-sub">Premium Vehicle Consulting, Sales & Finance Solutions</div>
      </div>
      <div class="invoice-badge-block">
        <div class="invoice-badge-title">TAX / SALE INVOICE</div>
        <div class="invoice-meta"><strong>Invoice No:</strong> ${data.invoiceNumber}</div>
        <div class="invoice-meta"><strong>Date:</strong> $displayDate</div>
        <div><span class="status-badge">COMPLETED / FULLY SETTLED</span></div>
      </div>
    </div>

    <div class="grid-section">
      <div>
        <div class="section-title">Customer Information</div>
        <div class="info-row">
          <span class="info-label">Customer Name:</span>
          <span class="info-value">${data.customerName}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Contact Phone:</span>
          <span class="info-value">${data.customerPhone}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Sale Date:</span>
          <span class="info-value">$displayDate</span>
        </div>
        <div class="info-row">
          <span class="info-label">Payment Mode:</span>
          <span class="info-value">$paymentDisplay</span>
        </div>
      </div>

      <div>
        <div class="section-title">Vehicle Information</div>
        <div class="info-row">
          <span class="info-label">Vehicle Name:</span>
          <span class="info-value">${data.vehicleName} (${data.vehicleModel})</span>
        </div>
        <div class="info-row">
          <span class="info-label">Registration No:</span>
          <span class="info-value"><span class="plate-badge">${data.vehicleNumber}</span></span>
        </div>
        <div class="info-row">
          <span class="info-label">Vehicle Type:</span>
          <span class="info-value">${data.vehicleType}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Mfg / Reg Year:</span>
          <span class="info-value">${data.manufacturingYear} / ${data.registrationYear}</span>
        </div>
      </div>
    </div>

    <table class="items-table">
      <thead>
        <tr>
          <th>#</th>
          <th>Description</th>
          <th class="text-right">Amount</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>1</td>
          <td>
            <strong>Vehicle Sale Consideration</strong><br>
            <span style="font-size: 12px; color: #64748b;">${data.vehicleName} ${data.vehicleModel} [${data.vehicleNumber}]</span>
          </td>
          <td class="text-right"><strong>$formattedSalePrice</strong></td>
        </tr>
        ${data.documentCharges > 0 ? '''<tr>
          <td>2</td>
          <td>
            <strong>Documentation & Processing Charges</strong><br>
            <span style="font-size: 12px; color: #64748b;">RC Transfer & Paperwork clearance fees</span>
          </td>
          <td class="text-right"><strong>$formattedDocCharges</strong></td>
        </tr>''' : ''}
      </tbody>
    </table>

    <div class="totals-wrapper">
      <table class="totals-table">
        <tr>
          <td class="label">Vehicle Base Price:</td>
          <td class="val">$formattedSalePrice</td>
        </tr>
        ${data.documentCharges > 0 ? '''<tr>
          <td class="label">Document Charges:</td>
          <td class="val">$formattedDocCharges</td>
        </tr>''' : ''}
        <tr class="grand-total-row">
          <td>Total Net Price:</td>
          <td class="val" style="color: #2563eb;">$formattedTotal</td>
        </tr>
        <tr>
          <td class="label">Amount Paid:</td>
          <td class="val" style="color: #166534;">$formattedPaid</td>
        </tr>
        <tr>
          <td class="label">Balance Remaining:</td>
          <td class="val" style="color: #166534;">$formattedBalance</td>
        </tr>
      </table>
    </div>

    <div class="settlement-badge">
      <div><strong>Status:</strong> Payment fully received and settled. Ownership transfer initiated.</div>
      <div><strong>Payment Type:</strong> $paymentDisplay</div>
    </div>

    <div class="signatures-block">
      <div class="sign-card">Customer Signature</div>
      <div class="sign-card">Authorized Signatory<br><strong>Vehicle Consulting</strong></div>
    </div>
  </div>
</body>
</html>''';
  }

  /// Write HTML invoice to a temporary file for viewing.
  Future<File> generateAndSaveInvoiceHtml(InvoiceData data) async {
    final tempDir = await getTemporaryDirectory();
    final sanitizedNum = data.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '_');
    final file = File('${tempDir.path}/Invoice_$sanitizedNum.html');
    final html = buildHtmlInvoice(data);
    await file.writeAsString(html);
    return file;
  }

  /// Launch invoice in the default web browser (Chrome/Edge) with instant Print option.
  Future<void> openInvoiceInBrowser(InvoiceData data) async {
    final file = await generateAndSaveInvoiceHtml(data);
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', file.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [file.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [file.path]);
    }
  }

  /// Allow user to choose a directory and save the invoice HTML file.
  Future<String?> exportInvoiceHtml(InvoiceData data) async {
    final sanitizedNum = data.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '_');
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Vehicle Invoice As',
      fileName: 'Invoice_$sanitizedNum.html',
      type: FileType.custom,
      allowedExtensions: ['html'],
    );
    if (savePath != null) {
      final file = File(savePath);
      final html = buildHtmlInvoice(data);
      await file.writeAsString(html);
      return savePath;
    }
    return null;
  }

  /// Display in-app invoice dialog preview.
  static Future<void> showInvoiceDialog(BuildContext context, InvoiceData data) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InvoiceDialog(invoiceData: data),
    );
  }

  /// Helper to check if a vehicle is eligible for invoice generation (Completed vehicles only).
  static bool canGenerateInvoice(VehicleModel vehicle) {
    return vehicle.status == VehicleStatus.completed;
  }
}

/// Global provider for InvoiceService
final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService();
});
