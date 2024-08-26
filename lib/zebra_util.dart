import 'dart:async';
import 'package:flutter/services.dart';
import 'package:zebrautil/zebra_printer.dart';

class ZebraUtil {
  static const MethodChannel _channel = const MethodChannel('zebrautil');

  static Future<ZebraPrinter> getPrinterInstance( 
      {required Function(String name, String ipAddress, bool isWifi) onPrinterFound,
      onPrinterDiscoveryDone,
      required Function(int errorCode, String errorText) onDiscoveryError,
      required Function(String status, String color) onChangePrinterStatus,
      onPermissionDenied}) async {
    String id =
        await _channel.invokeMethod("getInstance");
    ZebraPrinter printer = ZebraPrinter(id, onPrinterFound,
        onPrinterDiscoveryDone, onDiscoveryError, onChangePrinterStatus,
        onPermissionDenied: onPermissionDenied);
    return printer;
  }
}
