package com.example.rentalapp

import android.os.Bundle
import android.widget.Toast
import com.sun.jna.Pointer
import com.sun.jna.WString
import com.caysn.autoreplyprint.AutoReplyPrint
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.rentalapp/printer"
    private var h: Pointer? = null
    private val discoveredPrinterIps = mutableListOf<String>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "printBill" -> {
                    val printerIp = call.argument<String>("printerIp")
                    val billText = call.argument<String>("billText")

                    if (printerIp.isNullOrEmpty()) {
                        result.error("INVALID_IP", "Printer IP is null or empty", null)
                        return@setMethodCallHandler
                    }
                    if (billText == null) {
                        result.error("INVALID_TEXT", "Bill text is null", null)
                        return@setMethodCallHandler
                    }

                    val printSuccess = printBillToPrinter(printerIp, billText)
                    if (printSuccess) {
                        result.success("Print successful to $printerIp")
                    } else {
                        result.error("PRINT_FAILED", "Failed to print to $printerIp", null)
                    }
                }
                "discoverPrinters" -> {
                    Thread {
                        discoveredPrinterIps.clear()
                        val cancelFlag = com.sun.jna.ptr.IntByReference(0)
                        val callback = AutoReplyPrint.CP_OnNetPrinterDiscovered_Callback { _, _, discoveredIp, _, _ ->
                            if (!discoveredIp.isNullOrEmpty() && !discoveredPrinterIps.contains(discoveredIp)) {
                                discoveredPrinterIps.add(discoveredIp)
                            }
                        }
                        AutoReplyPrint.INSTANCE.CP_Port_EnumNetPrinter(3000, cancelFlag, callback, null)
                        runOnUiThread {
                            result.success(discoveredPrinterIps)
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun printBillToPrinter(printerIp: String, billText: String): Boolean {
        try {
            // Close port if already opened 
            if (h != null && AutoReplyPrint.INSTANCE.CP_Port_IsOpened(h)) {
                AutoReplyPrint.INSTANCE.CP_Port_Close(h)
                h = null
            }

            // Open port to printer
            h = AutoReplyPrint.INSTANCE.CP_Port_OpenTcp(null, printerIp, 9100.toShort(), 5000, 1)
            if (h == null || h == Pointer.NULL) {
                runOnUiThread {
                    Toast.makeText(this, "Failed to open port to printer $printerIp", Toast.LENGTH_SHORT).show()
                }
                h = null
                return false
            }

            AutoReplyPrint.INSTANCE.CP_Pos_ResetPrinter(h)
            AutoReplyPrint.INSTANCE.CP_Pos_SetMultiByteMode(h)
            AutoReplyPrint.INSTANCE.CP_Pos_SetMultiByteEncoding(h, AutoReplyPrint.CP_MultiByteEncoding_UTF8)

            val success = AutoReplyPrint.INSTANCE.CP_Pos_PrintTextInUTF8(h, WString(billText))
            if (!success) {
                runOnUiThread {
                    Toast.makeText(this, "Failed to send print data", Toast.LENGTH_SHORT).show()
                }
                AutoReplyPrint.INSTANCE.CP_Port_Close(h)
                h = null
                return false
            }

            AutoReplyPrint.INSTANCE.CP_Pos_FeedLine(h, 3)
            AutoReplyPrint.INSTANCE.CP_Port_Close(h)
            h = null

            runOnUiThread {
                Toast.makeText(this, "Print job sent successfully", Toast.LENGTH_SHORT).show()
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            if (h != null && AutoReplyPrint.INSTANCE.CP_Port_IsOpened(h)) {
                AutoReplyPrint.INSTANCE.CP_Port_Close(h)
                h = null
            }
            runOnUiThread {
                Toast.makeText(this, "Print error: ${e.message}", Toast.LENGTH_LONG).show()
            }
            return false
        }
    }
}
