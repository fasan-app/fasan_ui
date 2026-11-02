// fasan_ui – Android-Teil: Neigung für das Glas-Licht. MPL-2.0
//
// Quellen (developer.android.com):
// - guide/topics/sensors/sensors_position: TYPE_GAME_ROTATION_VECTOR nutzt kein Magnetfeld; relative Drehungen genauer,
//   nicht von Magnetfeldern gestört. Genau das braucht ein Licht-Reflex (Norden ist egal).
// - SensorManager.getRotationMatrixFromVector / getOrientation: Winkel in Radiant [azimut, pitch, roll].
// - registerListener(listener, sensor, samplingPeriodUs): Takt ist nur ein Wunsch. 33 ms (~30 Hz) liegt weit unter der
//   Grenze von 200 Hz, ab der Android 12 die Berechtigung HIGH_SAMPLING_RATE_SENSORS verlangt (Sensors overview,
//   „Sensor rate-limiting“ – nicht erneut abgerufen).
// Rückfall ohne Rotationsvektor (manche Geräte, Emulator ohne Fusion): Schwerkraft aus TYPE_ACCELEROMETER.
// Keine Berechtigung; Werte verlassen das Gerät nicht; Abo nur, solange Dart zuhört.
package app.fasan.ui

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel
import kotlin.math.atan2
import kotlin.math.sqrt

class FasanTilt(private val context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private var sink: EventChannel.EventSink? = null
    private var manager: SensorManager? = null
    private var source = ""
    private val matrix = FloatArray(9)
    private val angles = FloatArray(3)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        val m = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        manager = m
        val rotation = m.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
        val sensor = rotation ?: m.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (sensor == null) {
            events?.error("no_sensor", "Kein Lagesensor", null)
            return
        }
        source = if (rotation != null) "game_rotation_vector" else "accelerometer"
        m.registerListener(this, sensor, 33_000)
    }

    override fun onCancel(arguments: Any?) {
        manager?.unregisterListener(this)
        manager = null
        sink = null
    }

    override fun onSensorChanged(e: SensorEvent) {
        val pitch: Double
        val roll: Double
        if (e.sensor.type == Sensor.TYPE_GAME_ROTATION_VECTOR) {
            SensorManager.getRotationMatrixFromVector(matrix, e.values)
            SensorManager.getOrientation(matrix, angles)
            pitch = angles[1].toDouble()
            roll = angles[2].toDouble()
        } else {
            // Gravity direction in device axes (x right, y up, z out of the screen; Sensor coordinate system).
            val x = e.values[0].toDouble(); val y = e.values[1].toDouble(); val z = e.values[2].toDouble()
            pitch = -atan2(y, sqrt(x * x + z * z))
            roll = atan2(-x, z)
        }
        sink?.success(listOf(pitch, roll, e.timestamp / 1e6, source))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
