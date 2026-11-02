// fasan_ui – Android-Teil: Akkustand, Energiesparmodus und Wärmestatus für die Akku-Stufen. MPL-2.0
//
// Quellen (developer.android.com, Referenz; Methoden in android.jar API 36 geprüft):
// - PowerManager.isPowerSaveMode(), ACTION_POWER_SAVE_MODE_CHANGED (API 21)
// - PowerManager.getCurrentThermalStatus(), addThermalStatusListener (API 29)
// - BatteryManager.BATTERY_PROPERTY_CAPACITY (API 21); Intent.ACTION_BATTERY_CHANGED (sticky)
// Keine Berechtigung nötig; keine Daten verlassen das Gerät.
package app.fasan.ui

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FasanUiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private var sink: EventChannel.EventSink? = null
    private var receiver: BroadcastReceiver? = null
    private var thermalListener: Any? = null
    private var tiltEvents: EventChannel? = null
    private var tilt: FasanTilt? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "app.fasan.ui/power")
        methods.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "app.fasan.ui/power/events")
        events.setStreamHandler(this)
        tilt = FasanTilt(context)
        tiltEvents = EventChannel(binding.binaryMessenger, "app.fasan.ui/tilt").also { it.setStreamHandler(tilt) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        tiltEvents?.setStreamHandler(null)
        tilt?.onCancel(null)
        stopListening()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "state" -> result.success(state(null))
            // Settings.ACTION_BATTERY_SAVER_SETTINGS (API 22). Apps cannot switch battery saver themselves.
            "openBatterySaver" -> result.success(openBatterySaver())
            else -> result.notImplemented()
        }
    }

    private fun openBatterySaver(): Boolean = runCatching {
        val i = Intent(android.provider.Settings.ACTION_BATTERY_SAVER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(i)
        true
    }.getOrDefault(false)

    /** Current state as a map: battery (0–100 or null), charging, powerSave, thermal (THERMAL_STATUS_* or -1). */
    private fun state(battery: Intent?): Map<String, Any?> {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        // Sticky broadcast: registerReceiver(null, …) returns the last ACTION_BATTERY_CHANGED intent without registering.
        val sticky = battery ?: context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        var level: Int? = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        // getIntProperty returns Integer.MIN_VALUE (or 0 on some devices) if unsupported; then use the intent extras.
        if (level == null || level <= 0 || level > 100) {
            val l = sticky?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val s = sticky?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            level = if (l >= 0 && s > 0) l * 100 / s else null
        }
        val status = sticky?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        val thermal = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) pm.currentThermalStatus else -1
        return mapOf(
            "battery" to level,
            "charging" to charging,
            "powerSave" to pm.isPowerSaveMode,
            "thermal" to thermal,
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        val r = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                val battery = if (intent?.action == Intent.ACTION_BATTERY_CHANGED) intent else null
                sink?.success(state(battery))
            }
        }
        val filter = IntentFilter().apply {
            addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
            addAction(Intent.ACTION_BATTERY_CHANGED)
        }
        // Both actions are system broadcasts. Context.registerReceiver(…, flags) exists since API 33; with
        // RECEIVER_NOT_EXPORTED the receiver still gets system broadcasts (Android-Doku zu registerReceiver,
        // nicht erneut abgerufen – auf dem Gerät prüfen: Akku-Stufe wechselt beim Einschalten des Energiesparmodus).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(r, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(r, filter)
        }
        receiver = r
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val l = PowerManager.OnThermalStatusChangedListener { sink?.success(state(null)) }
            pm.addThermalStatusListener(context.mainExecutor, l)
            thermalListener = l
        }
        sink?.success(state(null))
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
    }

    private fun stopListening() {
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        receiver = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            (thermalListener as? PowerManager.OnThermalStatusChangedListener)?.let {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                pm.removeThermalStatusListener(it)
            }
        }
        thermalListener = null
        sink = null
    }
}
