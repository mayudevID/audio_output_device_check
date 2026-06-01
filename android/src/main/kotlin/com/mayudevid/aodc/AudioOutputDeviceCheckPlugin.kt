package com.mayudevid.aodc

import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AudioOutputDeviceCheckPlugin */
class AudioOutputDeviceCheckPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var audioManager: AudioManager
    private var eventSink: EventChannel.EventSink? = null
    private var audioDeviceReceiver: BroadcastReceiver? = null
    private var audioDeviceCallback: AudioDeviceCallback? = null

    private var bluetoothProfileListener: BluetoothProfile.ServiceListener? = null
    private var bluetoothA2dp: BluetoothA2dp? = null
    private var bluetoothHeadset: BluetoothHeadset? = null
    private var lastKnownBluetoothAudioDeviceName: String? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: Result? = null
    private val requestCodeBluetoothConnectPermission = 17791

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "audio_output_device_check")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "audio_output_device_check/events")
        eventChannel.setStreamHandler(this)

        initBluetoothProfiles()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getCurrentDevice" -> {
                val info = getCurrentDeviceInfo()
                // If there is an active listener, also refresh the stream so UI updates
                // after changes like granting runtime permissions.
                eventSink?.success(info)
                result.success(info)
            }
            "getBluetoothConnectPermissionStatus" -> {
                result.success(getBluetoothConnectPermissionStatusName())
            }
            "requestBluetoothConnectPermission" -> {
                requestBluetoothConnectPermission(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        closeBluetoothProfiles()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != requestCodeBluetoothConnectPermission) return false

        val pending = pendingPermissionResult
        pendingPermissionResult = null
        pending?.success(getBluetoothConnectPermissionStatusName())
        return true
    }

    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        initBluetoothProfiles()
        registerAudioDeviceListeners()
        // Send initial state immediately
        sendCurrentDeviceInfo()
    }

    override fun onCancel(arguments: Any?) {
        unregisterAudioDeviceListeners()
        eventSink = null
    }

    private fun initBluetoothProfiles() {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter() ?: return
        if (bluetoothProfileListener != null) return

        bluetoothProfileListener = object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                when (profile) {
                    BluetoothProfile.A2DP -> bluetoothA2dp = proxy as? BluetoothA2dp
                    BluetoothProfile.HEADSET -> bluetoothHeadset = proxy as? BluetoothHeadset
                }
                refreshConnectedBluetoothAudioDeviceName()
            }

            override fun onServiceDisconnected(profile: Int) {
                when (profile) {
                    BluetoothProfile.A2DP -> bluetoothA2dp = null
                    BluetoothProfile.HEADSET -> bluetoothHeadset = null
                }
            }
        }

        try {
            bluetoothAdapter.getProfileProxy(context, bluetoothProfileListener, BluetoothProfile.A2DP)
            bluetoothAdapter.getProfileProxy(context, bluetoothProfileListener, BluetoothProfile.HEADSET)
        } catch (e: Exception) {
            android.util.Log.w("AudioOutputDevice", "Failed to init BT profiles: ${e.message}")
        }
    }

    private fun closeBluetoothProfiles() {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter() ?: return
        try {
            bluetoothA2dp?.let { bluetoothAdapter.closeProfileProxy(BluetoothProfile.A2DP, it) }
        } catch (_: Exception) {
        }
        try {
            bluetoothHeadset?.let { bluetoothAdapter.closeProfileProxy(BluetoothProfile.HEADSET, it) }
        } catch (_: Exception) {
        }

        bluetoothA2dp = null
        bluetoothHeadset = null
        bluetoothProfileListener = null
    }

    private fun refreshConnectedBluetoothAudioDeviceName() {
        // Prefer A2DP (music) device name if available.
        try {
            bluetoothA2dp?.connectedDevices?.firstOrNull()?.let { device ->
                lastKnownBluetoothAudioDeviceName = device.safeName()
                return
            }
        } catch (e: SecurityException) {
            android.util.Log.w("AudioOutputDevice", "No BLUETOOTH_CONNECT permission (A2DP)")
        } catch (_: Exception) {
        }

        // Fallback to headset profile (SCO) if available.
        try {
            bluetoothHeadset?.connectedDevices?.firstOrNull()?.let { device ->
                lastKnownBluetoothAudioDeviceName = device.safeName()
            }
        } catch (e: SecurityException) {
            android.util.Log.w("AudioOutputDevice", "No BLUETOOTH_CONNECT permission (HEADSET)")
        } catch (_: Exception) {
        }
    }

    private fun resolveBluetoothDeviceName(reportedName: String?): String {
        val normalizedReported = (reportedName ?: "").trim()
        val fallbackReported = if (normalizedReported.isNotEmpty()) normalizedReported else "Bluetooth Device"

        val localAdapterName = try {
            BluetoothAdapter.getDefaultAdapter()?.name?.trim()?.takeIf { it.isNotEmpty() }
        } catch (_: Exception) {
            null
        }

        val cachedName = lastKnownBluetoothAudioDeviceName?.trim()?.takeIf { it.isNotEmpty() }
        if (cachedName == null) return fallbackReported

        // Some OEMs incorrectly report the phone's BT name/model as the audio device name.
        val looksLikeLocalDeviceName = localAdapterName != null && fallbackReported.equals(localAdapterName, ignoreCase = true)
        val looksLikePhoneModel = fallbackReported.equals(Build.MODEL, ignoreCase = true) ||
            fallbackReported.equals(Build.DEVICE, ignoreCase = true)
        val looksGeneric = fallbackReported.equals("Bluetooth Device", ignoreCase = true)

        return if (looksLikeLocalDeviceName || looksLikePhoneModel || looksGeneric) cachedName else fallbackReported
    }

    private fun registerAudioDeviceListeners() {
        // Use AudioDeviceCallback for API 23+ for more accurate detection
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (audioDeviceCallback == null) {
                audioDeviceCallback = object : AudioDeviceCallback() {
                    override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                        super.onAudioDevicesAdded(addedDevices)
                        // Delay slightly to allow audio routing to update
                        Handler(Looper.getMainLooper()).postDelayed({
                            sendCurrentDeviceInfo()
                        }, 500)
                    }

                    override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                        super.onAudioDevicesRemoved(removedDevices)
                        sendCurrentDeviceInfo()
                    }
                }
                audioManager.registerAudioDeviceCallback(audioDeviceCallback, null)
            }
        }

        // Also register BroadcastReceiver for additional events
        registerAudioDeviceReceiver()
    }

    private fun registerAudioDeviceReceiver() {
        if (audioDeviceReceiver != null) return

        audioDeviceReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    AudioManager.ACTION_HEADSET_PLUG,
                    AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED,
                    BluetoothDevice.ACTION_ACL_CONNECTED,
                    BluetoothDevice.ACTION_ACL_DISCONNECTED,
                    BluetoothAdapter.ACTION_STATE_CHANGED -> {
                        if (intent.action == BluetoothDevice.ACTION_ACL_CONNECTED) {
                            try {
                                val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                                }

                                device?.safeName()?.let { connectedName ->
                                    lastKnownBluetoothAudioDeviceName = connectedName
                                }
                            } catch (_: Exception) {
                            }
                        }

                        refreshConnectedBluetoothAudioDeviceName()
                        // Delay slightly to allow audio routing to update
                        Handler(Looper.getMainLooper()).postDelayed({
                            sendCurrentDeviceInfo()
                        }, 500)
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(AudioManager.ACTION_HEADSET_PLUG)
            addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
        }

        try {
            context.registerReceiver(audioDeviceReceiver, filter)
        } catch (e: Exception) {
            android.util.Log.e("AudioOutputDevice", "Failed to register receiver: ${e.message}")
        }
    }

    private fun unregisterAudioDeviceListeners() {
        // Unregister AudioDeviceCallback
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioDeviceCallback?.let {
                audioManager.unregisterAudioDeviceCallback(it)
                audioDeviceCallback = null
            }
        }

        // Unregister BroadcastReceiver
        unregisterAudioDeviceReceiver()
    }

    private fun unregisterAudioDeviceReceiver() {
        audioDeviceReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                android.util.Log.e("AudioOutputDevice", "Failed to unregister receiver: ${e.message}")
            }
            audioDeviceReceiver = null
        }
    }

    private fun sendCurrentDeviceInfo() {
        eventSink?.success(getCurrentDeviceInfo())
    }

    private fun getBluetoothConnectPermissionStatusName(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return "notApplicable"
        }

        val granted = ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) return "granted"

        val activity = activityBinding?.activity ?: return "denied"
        return if (activity.shouldShowRequestPermissionRationale(
                android.Manifest.permission.BLUETOOTH_CONNECT
            )
        ) {
            "denied"
        } else {
            "permanentlyDenied"
        }
    }

    private fun requestBluetoothConnectPermission(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.success("notApplicable")
            return
        }

        if (getBluetoothConnectPermissionStatusName() == "granted") {
            result.success("granted")
            return
        }

        val binding = activityBinding
        if (binding == null) {
            result.success("denied")
            return
        }

        pendingPermissionResult = result
        binding.activity.requestPermissions(
            arrayOf(android.Manifest.permission.BLUETOOTH_CONNECT),
            requestCodeBluetoothConnectPermission
        )
    }

    private fun getCurrentDeviceInfo(): Map<String, String> {
        // For Android M (API 23) and above, use AudioDeviceInfo with proper routing check
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Get all OUTPUT devices
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

            // Priority 1: Check for Bluetooth A2DP (music) devices
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP) {
                    // Check if this device is a sink (output) and not just connected
                    if (device.isSink) {
                        val deviceName = resolveBluetoothDeviceName(device.productName?.toString())
                        android.util.Log.d("AudioOutputDevice", "Found Bluetooth A2DP: $deviceName")
                        return mapOf(
                            "type" to "bluetooth",
                            "name" to deviceName
                        )
                    }
                }
            }

            // Priority 2: Check for Bluetooth SCO (call) devices
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) {
                    if (device.isSink) {
                        val deviceName = resolveBluetoothDeviceName(device.productName?.toString())
                        android.util.Log.d("AudioOutputDevice", "Found Bluetooth SCO: $deviceName")
                        return mapOf(
                            "type" to "bluetooth",
                            "name" to deviceName
                        )
                    }
                }
            }

            // Priority 3: Check for wired headphones/headset
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                    device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                    device.type == AudioDeviceInfo.TYPE_USB_HEADSET) {
                    android.util.Log.d("AudioOutputDevice", "Found wired device")
                    return mapOf(
                        "type" to "wired",
                        "name" to "Audio output device"
                    )
                }
            }

            // Priority 4: Check if speaker is being used
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER) {
                    android.util.Log.d("AudioOutputDevice", "Using built-in speaker")
                    // Continue checking, as speaker is always available
                }
            }
        } else {
            // Fallback for older Android versions (API < 23)
            @Suppress("DEPRECATION")
            if (audioManager.isWiredHeadsetOn) {
                return mapOf(
                    "type" to "wired",
                    "name" to "Audio output device"
                )
            }

            @Suppress("DEPRECATION")
            if (audioManager.isBluetoothA2dpOn || audioManager.isBluetoothScoOn) {
                val deviceName = getConnectedBluetoothDeviceNameLegacy()
                return mapOf(
                    "type" to "bluetooth",
                    "name" to deviceName
                )
            }
        }

        // Default to built-in speaker
        android.util.Log.d("AudioOutputDevice", "Defaulting to speaker")
        return mapOf(
            "type" to "speaker",
            "name" to "Speaker"
        )
    }

    @Suppress("DEPRECATION")
    private fun getConnectedBluetoothDeviceNameLegacy(): String {
        try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter?.isEnabled == true) {
                val pairedDevices = bluetoothAdapter.bondedDevices
                // Return the name of the first paired device
                pairedDevices?.firstOrNull()?.name?.let {
                    return it
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AudioOutputDevice", "Error getting Bluetooth device name: ${e.message}")
        }
        return "Bluetooth Device"
    }

    private fun BluetoothDevice.safeName(): String? {
        return try {
            this.name?.trim()?.takeIf { it.isNotEmpty() }
        } catch (_: SecurityException) {
            null
        } catch (_: Exception) {
            null
        }
    }
}
