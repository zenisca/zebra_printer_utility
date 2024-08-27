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
      home: FutureBuilder(
        future: ZebraUtil.getPrinterInstance(),
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
  late ZebraPrinterNotifier notifier;

  @override
  void initState() {
    zebraPrinter = widget.printer;
    notifier = zebraPrinter.notifier;
    zebraPrinter.discoveryPrinters();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("My Printers"),
        ),
        body: ListenableBuilder(
          listenable: zebraPrinter.notifier,
          builder: (context, child) {
            final printers = notifier.printers;
            if (printers.isEmpty) {
              return const Center(
                child: Text("Printers not found"),
              );
            }
            return ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                      title: Text(printers[index].name),
                      subtitle: Text(printers[index].status,
                          style: TextStyle(color: printers[index].color)),
                      leading: Icon(Icons.print, color: printers[index].color),
                      onTap: () {
                        zebraPrinter.connectToPrinter(printers[index].address);
                      });
                },
                itemCount: printers.length);
          },
        ));
  }
}
