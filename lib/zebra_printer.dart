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
  late ZebraPrinterNotifier notifier;
  String? selectedAddress;

  ZebraPrinter(String id,
      {this.onDiscoveryError,
      this.onPermissionDenied,
      ZebraPrinterNotifier? notifier}) {
    channel = MethodChannel('ZebraPrinterObject' + id);
    channel.setMethodCallHandler(nativeMethodCallHandler);
    this.notifier = notifier ?? ZebraPrinterNotifier();
  }

  void discoveryPrinters() {
    notifier.isDone = false;
    channel.invokeMethod("checkPermission").then((isGrantPermission) {
      if (isGrantPermission) {
        channel.invokeMethod("discoverPrinters");
      } else {
        notifier.isDone = true;
        if (onPermissionDenied != null) onPermissionDenied!();
      }
    });
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

  Future<void> connectToPrinter(String address) async {
    if(selectedAddress != null){
      await disconnect(address: address);
      await Future.delayed(Durations.medium1);
    }
    if(selectedAddress == address){
      await disconnect(address: address);
      selectedAddress = null;
      return;
    }
    selectedAddress = address;
    channel.invokeMethod("connectToPrinter", {"Address": address});
  }

  void connectToGenericPrinter(String address) {
    if(selectedAddress != null){
      disconnect(address: address);
    }
    selectedAddress = address;
    channel.invokeMethod("connectToGenericPrinter", {"Address": address});
  }

  void print(String data) {
    if (!data.contains("^PON")) data = data.replaceAll("^XA", "^XA^PON");

    if (isRotated) {
      data = data.replaceAll("^PON", "^POI");
    }
    channel.invokeMethod("print", {"Data": data});
  }

  Future<void> disconnect({required String address}) async {
    await channel.invokeMethod("disconnect", null);
    notifier.disconnectPrinter(address);
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
        connected: false,
        isWifi: methodCall.arguments["IsWifi"] == "true",
      );
      notifier.addPrinter(newPrinter);
    } else if (methodCall.method == "changePrinterStatus") {
      final String status = methodCall.arguments["Status"];
      final String color = methodCall.arguments["Color"];
      notifier.updatePrinterStatus(status, color, selectedAddress);
    } else if (methodCall.method == "onPrinterDiscoveryDone") {
      notifier.isDone = true;
    } else if (methodCall.method == "onDiscoveryError" &&
        onDiscoveryError != null) {
      onDiscoveryError!(
          methodCall.arguments["ErrorCode"], methodCall.arguments["ErrorText"]);
    }
  }

  String? id;
}

class ZebraPrinterNotifier extends ChangeNotifier {
  final List<ZebraDevice> _printers = [];
  List<ZebraDevice> get printers => List.unmodifiable(_printers);
  bool _isDone = false;
  
  void addPrinter(ZebraDevice printer) {
    if(_printers.contains(printer)) return;
    _printers.add(printer);
    notifyListeners();
  }

  void disconnectPrinter(String address) {
    final int index = _printers.indexWhere((element) => element.address == address);
    _printers[index] = _printers[index].copyWith(connected: false);
    notifyListeners();
  }

  void updatePrinterStatus(
      String status, String color, String? selectedAddress) {
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
      _printers[index] =
          _printers[index].copyWith(status: status, color: newColor);
      notifyListeners();
    }
  }

  set isDone(bool value) {
    _isDone = value;
    notifyListeners();
  }

  bool get isDone => _isDone;
}
