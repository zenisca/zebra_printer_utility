import 'package:flutter/material.dart';
import 'package:zebrautil/zebra_printer.dart';
import 'package:zebrautil/zebra_util.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PrinterTemplate(),
    );
  }
}

class PrinterTemplate extends StatefulWidget {
  const PrinterTemplate({super.key});

  @override
  State<PrinterTemplate> createState() => _PrinterTemplateState();
}

class _PrinterTemplateState extends State<PrinterTemplate> {
  late ZebraPrinter zebraPrinter;
  List<Map<String,String>> printers = [];

  @override
  void initState() {
    createInstance();
    super.initState();
  }

  void createInstance() async {
    zebraPrinter = await ZebraUtil.getPrinterInstance(
        onPrinterFound: (name, ipAddress, isWifi) {
          setState(() {
            printers.add({"ipAddress":ipAddress, "name": name});
          });
          print("onPrinterFound: $name, $ipAddress, $isWifi");
        },
        onPrinterDiscoveryDone: () => print("onPrinterDiscoveryDone"),
        onDiscoveryError: (onErrorCode, onErrorText) =>
            print("onDiscoveryError: $onErrorCode, $onErrorText"),
        onChangePrinterStatus: (status, color) {
          print("change printer status: " + status + color);
        },
        onPermissionDenied: () => print("onPermissionDenied"));
    zebraPrinter.rotate();
    zebraPrinter.discoveryPrinters();
  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Printers"),
      ),
      body: printers.isEmpty
          ? const Center(
              child: Text("Printers not found"),
            )
          : ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                    title: Text(printers[index]["name"]!),
                    leading: const Icon(Icons.print),
                    onTap: () {
                      zebraPrinter
                          .connectToGenericPrinter(printers[index]["ipAddress"]!);
                    });
              },
              itemCount: printers.length),
    );
  }
}
