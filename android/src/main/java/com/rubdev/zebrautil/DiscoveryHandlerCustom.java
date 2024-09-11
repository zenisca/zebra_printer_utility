package com.rubdev.zebrautil;

import com.zebra.sdk.printer.discovery.DiscoveredPrinter;
import com.zebra.sdk.printer.discovery.DiscoveryHandler;

///Custom discovery handler
public interface DiscoveryHandlerCustom extends DiscoveryHandler {
    void printerOutOfRange(DiscoveredPrinter discoverPrinter);


}
