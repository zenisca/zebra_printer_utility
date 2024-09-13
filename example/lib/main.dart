import 'package:flutter/material.dart';
import 'package:zebrautil/zebra_device.dart';
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
      home: FutureBuilder(
        future: ZebraUtil.getPrinterInstance(controller: ZebraController()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final printer = snapshot.data as ZebraPrinter;
          return PrinterTemplate(printer);
        },
      ),
    );
  }
}

class PrinterTemplate extends StatefulWidget {
  const PrinterTemplate(this.printer, {super.key});
  final ZebraPrinter printer;
  @override
  State<PrinterTemplate> createState() => _PrinterTemplateState();
}

class _PrinterTemplateState extends State<PrinterTemplate> {
  late ZebraPrinter zebraPrinter;
  late ZebraController notifier;
  final String dataToPrint = """^XA
        ^FX Top section with logo, name and address.
        ^CF0,60
        ^FO50,50^GB100,100,100^FS
        ^FO75,75^FR^GB100,100,100^FS
        ^FO93,93^GB40,40,40^FS
        ^FO220,50^FDIntershipping, Inc.^FS
        ^CF0,30
        ^FO220,115^FD1000 Shipping Lane^FS
        ^FO220,155^FDShelbyville TN 38102^FS
        ^FO220,195^FDUnited States (USA)^FS
        ^FO50,250^GB700,3,3^FS

        ^FX Second section with recipient address and permit information.
        ^CFA,30
        ^FO50,300^FDJohn Doe^FS
        ^FO50,340^FD100 Main Street^FS
        ^FO50,380^FDSpringfield TN 39021^FS
        ^FO50,420^FDUnited States (USA)^FS
        ^CFA,15
        ^FO600,300^GB150,150,3^FS
        ^FO638,340^FDPermit^FS
        ^FO638,390^FD123456^FS
        ^FO50,500^GB700,3,3^FS

        ^FX Third section with bar code.
        ^BY5,2,270
        ^FO100,550^BC^FD12345678^FS

        ^FX Fourth section (the two boxes on the bottom).
        ^FO50,900^GB700,250,3^FS
        ^FO400,900^GB3,250,3^FS
        ^CF0,40
        ^FO100,960^FDCtr. X34B-1^FS
        ^FO100,1010^FDREF1 F00B47^FS
        ^FO100,1060^FDREF2 BL4H8^FS
        ^CF0,190
        ^FO470,955^FDCA^FS

        ^XZ""";

  @override
  void initState() {
    zebraPrinter = widget.printer;
    notifier = zebraPrinter.controller;
    zebraPrinter.startScanning();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: _GetAppCustom(zebraPrinter.isScanning),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (zebraPrinter.isScanning) {
              zebraPrinter.stopScanning();
            } else {
              zebraPrinter.startScanning();
            }
            setState(() {});
          },
          child: Icon(
              zebraPrinter.isScanning ? Icons.stop_circle : Icons.play_circle),
        ),
        body: ListenableBuilder(
          listenable: zebraPrinter.controller,
          builder: (context, child) {
            final printers = notifier.printers;
            if (printers.isEmpty) {
              return _getNotAvailablePage();
            }
            return _getListDevices(printers);
          },
        ));
  }

  Widget _getListDevices(List<ZebraDevice> printers) {
    return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: InkWell(
                onTap: () {
                  zebraPrinter.connectToPrinter(printers[index].address);
                },
                child: Text(printers[index].name)),
            subtitle: Text(printers[index].status,
                style: TextStyle(color: printers[index].color)),
            leading: IconButton(
              icon: Icon(Icons.print, color: printers[index].color),
              onPressed: () {
                zebraPrinter.print(data: dataToPrint);
              },
            ),
          );
        },
        itemCount: printers.length);
  }

  SizedBox _getNotAvailablePage() {
    return const SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Printers not found"),
        ],
      ),
    );
  }
}

class _GetAppCustom extends StatelessWidget {
  const _GetAppCustom(this.isScanning);
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("My Printers"),
        if (isScanning)
          const Text(
            "Seaching for printers...",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
      ],
    );
  }
}
