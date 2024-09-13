import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zebrautil/zebra_device.dart';

enum EnumMediaType { Label, BlackMark, Journal }

enum Command { calibrate, mediaType, darkness }

enum StatusZebra { Connected, Disconnected, Disconnecting, Connecting }

class ZebraPrinter {
  late MethodChannel channel;

  Function(String, String?)? onDiscoveryError;
  Function? onPermissionDenied;
  bool isRotated = false;
  bool isScanning = false;
  bool shouldSync = false;
  late ZebraController controller;

  ZebraPrinter(String id,
      {this.onDiscoveryError,
      this.onPermissionDenied,
      ZebraController? controller}) {
    channel = MethodChannel('ZebraPrinterObject' + id);
    channel.setMethodCallHandler(nativeMethodCallHandler);
    this.controller = controller ?? ZebraController();
  }

  void startScanning() {
    isScanning = true;
    controller.cleanAll();
    channel.invokeMethod("checkPermission").then((isGrantPermission) {
      if (isGrantPermission) {
        channel.invokeMethod("startScan");
      } else {
        isScanning = false;
        if (onPermissionDenied != null) onPermissionDenied!();
      }
    });
  }

  void stopScanning() {
    isScanning = false;
    shouldSync = true;
    channel.invokeMethod("stopScan");
  }

  void _setSettings(Command setting, dynamic values) {
    String command = "";
    switch (setting) {
      case Command.mediaType:
        if (values == EnumMediaType.BlackMark) {
          command = '''
          ! U1 setvar "media.type" "label"
          ! U1 setvar "media.sense_mode" "bar"
          ''';
        } else if (values == EnumMediaType.Journal) {
          command = '''
          ! U1 setvar "media.type" "journal"
          ''';
        } else if (values == EnumMediaType.Label) {
          command = '''
          ! U1 setvar "media.type" "label"
           ! U1 setvar "media.sense_mode" "gap"
          ''';
        }

        break;
      case Command.calibrate:
        command = '''~jc^xa^jus^xz''';
        break;
      case Command.darkness:
        command = '''! U1 setvar "print.tone" "$values"''';
        break;
    }

    if (setting == Command.calibrate) {
      command = '''~jc^xa^jus^xz''';
    }

    try {
      channel.invokeMethod("setSettings", {"SettingCommand": command});
    } on PlatformException catch (e) {
      if (onDiscoveryError != null) onDiscoveryError!(e.code, e.message);
    }
  }

  void setOnDiscoveryError(Function(String, String?)? onDiscoveryError) {
    this.onDiscoveryError = onDiscoveryError;
  }

  void setOnPermissionDenied(Function(String, String) onPermissionDenied) {
    this.onPermissionDenied = onPermissionDenied;
  }

  void setDarkness(int darkness) {
    _setSettings(Command.darkness, darkness.toString());
  }

  void setMediaType(EnumMediaType mediaType) {
    _setSettings(Command.mediaType, mediaType);
  }

  void setLanguage({required String language}) {
    channel.invokeMethod("setLanguage", {"Language": language});
  }

  Future<void> connectToPrinter(String address) async {
    if (controller.selectedAddress != null) {
      await disconnect();
      await Future.delayed(Durations.medium1);
    }
    if (controller.selectedAddress == address) {
      await disconnect();
      controller.selectedAddress = null;
      return;
    }
    controller.selectedAddress = address;
    channel.invokeMethod("connectToPrinter", {"Address": address});
  }

  Future<void> connectToGenericPrinter(String address) async {
    if (controller.selectedAddress != null) {
      await disconnect();
      await Future.delayed(Durations.medium1);
    }
    if (controller.selectedAddress == address) {
      await disconnect();
      controller.selectedAddress = null;
      return;
    }
    controller.selectedAddress = address;
    channel.invokeMethod("connectToGenericPrinter", {"Address": address});
  }

  void print({required String data}) {
    if (!data.contains("^PON")) data = data.replaceAll("^XA", "^XA^PON");

    if (isRotated) {
      data = data.replaceAll("^PON", "^POI");
    }
    channel.invokeMethod("print", {"Data": data});
  }

  Future<void> disconnect() async {
    await channel.invokeMethod("disconnect", null);
  }

  void calibratePrinter() {
    _setSettings(Command.calibrate, null);
  }

  void isPrinterConnected() {
    channel.invokeMethod("isPrinterConnected");
  }

  void rotate() {
    this.isRotated = !this.isRotated;
  }

  Future<void> nativeMethodCallHandler(MethodCall methodCall) async {
    if (methodCall.method == "printerFound") {
      final newPrinter = ZebraDevice(
        address: methodCall.arguments["Address"],
        name: methodCall.arguments["Name"],
        isWifi: methodCall.arguments["IsWifi"] == "true",
      );
      controller.addPrinter(newPrinter);
    } else if (methodCall.method == "printerRemoved") {
      final String address = methodCall.arguments["Address"];
      controller.removePrinter(address);
    } else if (methodCall.method == "changePrinterStatus") {
      final String status = methodCall.arguments["Status"];
      final String color = methodCall.arguments["Color"];
      controller.updatePrinterStatus(status, color);
    } else if (methodCall.method == "onDiscoveryError" &&
        onDiscoveryError != null) {
      onDiscoveryError!(
          methodCall.arguments["ErrorCode"], methodCall.arguments["ErrorText"]);
    } else if (methodCall.method == "onDiscoveryDone") {
      if (shouldSync) {
        controller.synchronizePrinter();
        shouldSync = false;
      }
    }
  }
}

/// Notifier for printers, contains list of printers and methods to add, remove and update printers
class ZebraController extends ChangeNotifier {
  List<ZebraDevice> _printers = [];
  List<ZebraDevice> get printers => List.unmodifiable(_printers);
  String? selectedAddress;

  void addPrinter(ZebraDevice printer) {
    if (_printers.contains(printer)) return;
    _printers.add(printer);
    notifyListeners();
  }

  void removePrinter(String address) {
    _printers.removeWhere((element) => element.address == address);
    notifyListeners();
  }

  void cleanAll() {
    _printers.clear();
  }

  void updatePrinterStatus(String status, String color) {
    if (selectedAddress != null) {
      Color newColor = Colors.grey.withOpacity(0.6);
      switch (color) {
        case 'R':
          newColor = Colors.red;
          break;
        case 'G':
          newColor = Colors.green;
          break;
        default:
          newColor = Colors.grey.withOpacity(0.6);
          break;
      }
      final int index =
          _printers.indexWhere((element) => element.address == selectedAddress);
      _printers[index] = _printers[index].copyWith(
          status: status,
          color: newColor,
          isConnected: status == StatusZebra.Connected.name);
      notifyListeners();
    }
  }

  void synchronizePrinter() {
    if (selectedAddress == null) return;
    final int index =
        _printers.indexWhere((element) => element.address == selectedAddress);
    if (index == -1) {
      selectedAddress = null;
      return;
    }
    if (_printers[index].isConnected) return;
    _printers[index] = _printers[index].copyWith(
        status: StatusZebra.Connected.name,
        color: Colors.green,
        isConnected: true);
    notifyListeners();
  }
}
