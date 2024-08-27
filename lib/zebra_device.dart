import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:zebrautil/zebra_printer.dart';

List<ZebraDevice> zebraDevicesModelFromJson(String str) =>
    List<ZebraDevice>.from(
        json.decode(str).map((x) => ZebraDevice.fromJson(x)));

String zebraDevicesToJson(List<ZebraDevice> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

ZebraDevice zebraDeviceModelFromJson(String str) =>
    ZebraDevice.fromJson(jsonDecode(str));

class ZebraDevice {
  final String address;
  final String name;
  final String status;
  final bool connected;
  final bool isWifi;
  final Color color;

  ZebraDevice(
      {required this.address,
      required this.name,
      required this.isWifi,
      this.connected = false,
      this.color = const Color.fromARGB(255, 255, 0, 0),
      String? status})
      : status = status ?? StatusZebra.Disconnected.name;

  factory ZebraDevice.empty() =>
      ZebraDevice(address: "", name: "", isWifi: false);

  factory ZebraDevice.fromJson(Map<String, dynamic> json) => ZebraDevice(
      address: json["ipAddress"] ?? json["macAddress"],
      name: json["name"],
      connected: json["connected"] ?? false,
      isWifi: json["isWifi"].toString() == "true",
      status: json["status"] ?? StatusZebra.Disconnected.name,
      color: json["color"]);

  Map<String, dynamic> toJson() => {
        "ipAddress": address,
        "name": name,
        "connected": connected,
        "isWifi": isWifi,
        "status": status,
        "color": color
      };

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is ZebraDevice &&
        other.address == address &&
        other.name == name;
  }

  ZebraDevice copyWith(
      {String? ipAddress,
      String? name,
      bool? connected,
      bool? isWifi,
      String? status,
      Color? color}) {
    return ZebraDevice(
        address: ipAddress ?? this.address,
        name: name ?? this.name,
        connected: connected ?? this.connected,
        isWifi: isWifi ?? this.isWifi,
        status: status ?? this.status,
        color: color ?? this.color);
  }
}
