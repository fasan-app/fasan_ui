// fasan_ui – short UI tones through AudioTrack (MODE_STATIC). MPL-2.0
//
// Why not a media player: 0.1.24 used audioplayers' MediaPlayer. On the S23 the first tap sounded thin, later taps got louder and
// some fired late or twice (Nutzer 03.11.). A static AudioTrack holds the finished PCM in memory: no decoding, no start-up ramp,
// the same level every time. Source: developer.android.com/reference/android/media/AudioTrack (MODE_STATIC, reloadStaticData),
// AudioAttributes (USAGE_MEDIA, CONTENT_TYPE_SONIFICATION). Played tones never take audio focus, music keeps playing.
package app.fasan.ui

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import java.nio.ByteBuffer
import java.nio.ByteOrder

class FasanTone {
    private val tracks = HashMap<String, AudioTrack>()

    /** [pcm] is 16-bit little-endian mono. Replaces a tone of the same name. */
    fun load(name: String, pcm: ByteArray, rate: Int): Boolean {
        tracks.remove(name)?.release()
        val shorts = ShortArray(pcm.size / 2)
        ByteBuffer.wrap(pcm).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(shorts)
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(rate)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()
        val track = AudioTrack.Builder()
            .setAudioAttributes(attrs)
            .setAudioFormat(format)
            .setBufferSizeInBytes(pcm.size)
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()
        val written = track.write(shorts, 0, shorts.size)
        if (written != shorts.size) {
            track.release()
            return false
        }
        tracks[name] = track
        return true
    }

    /** Restarts the tone from its first sample. [volume] 0–1. Returns false if the tone was not loaded. */
    fun play(name: String, volume: Float): Boolean {
        val t = tracks[name] ?: return false
        return runCatching {
            t.setVolume(volume.coerceIn(0f, 1f))
            if (t.playState != AudioTrack.PLAYSTATE_STOPPED) t.stop()
            t.reloadStaticData()
            t.play()
            true
        }.getOrDefault(false)
    }

    fun release() {
        tracks.values.forEach { runCatching { it.release() } }
        tracks.clear()
    }
}
