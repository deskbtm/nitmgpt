package im.zoe.labs.flutter_notification_listener

import android.app.ActivityManager
import android.content.*
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.nio.ByteBuffer
import java.util.*


class FlutterNotificationListenerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
  private var eventSink: EventChannel.EventSink? = null

  private lateinit var mContext: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Log.i(TAG, "on attached to engine")

    mContext = flutterPluginBinding.applicationContext

    val binaryMessenger = flutterPluginBinding.binaryMessenger

    // event stream channel
    EventChannel(binaryMessenger, EVENT_CHANNEL_NAME).setStreamHandler(this)
    // method channel
    MethodChannel(binaryMessenger, METHOD_CHANNEL_NAME).setMethodCallHandler(this)

    // store the flutter engine
    val engine = flutterPluginBinding.flutterEngine
    FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_CACHE_KEY, engine)

    // TODO: remove those code
    val receiver = NotificationReceiver()
    val intentFilter = IntentFilter()
    intentFilter.addAction(NotificationsHandlerService.NOTIFICATION_INTENT)
    mContext.registerReceiver(receiver, intentFilter)

    Log.i(TAG, "attached engine finished")
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    // methodChannel.setMethodCallHandler(null)
  }

  @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
  override fun onListen(o: Any?, eventSink: EventChannel.EventSink?) {
    this.eventSink = eventSink
  }

  override fun onCancel(o: Any?) {
    eventSink = null
  }

  internal inner class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      eventSink?.success(intent.getStringExtra(NotificationsHandlerService.NOTIFICATION_INTENT_KEY)?:"{}")
    }
  }

  companion object {
    const val TAG = "ListenerPlugin"

    private const val EVENT_CHANNEL_NAME = "flutter_notification_listener/events"
    private const val METHOD_CHANNEL_NAME = "flutter_notification_listener/method"

    const val SHARED_PREFERENCES_KEY = "flutter_notification_cache"

    const val CALLBACK_DISPATCHER_HANDLE_KEY = "callback_dispatch_handler"
    const val PROMOTE_SERVICE_ARGS_KEY = "promote_service_args"
    const val CALLBACK_HANDLE_KEY = "callback_handler"

    const val FLUTTER_ENGINE_CACHE_KEY = "flutter_engine_main"

    private val sNotificationCacheLock = Object()

    fun registerAfterReboot(context: Context) {
      synchronized(sNotificationCacheLock) {
        Log.i(TAG, "try to start service after reboot")
        internalStartService(context, null)
      }
    }

    private fun initialize(context: Context, cbId: Long) {
      Log.d(TAG, "plugin init: install callback and notify the service flutter engine changed")
      context.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
        .edit()
        .putLong(CALLBACK_DISPATCHER_HANDLE_KEY, cbId)
        .apply()

      // TODO: update the flutter engine
      // call the service to update the flutter engine
      NotificationsHandlerService.updateFlutterEngine(context)
    }

    fun internalStartService(context: Context, cfg: Utils.PromoteServiceConfig?): Boolean {
      if (!NotificationsHandlerService.permissionGiven(context)) {
        Log.e(TAG, "can't get permission to start service.")
        return false
      }

      Log.d(TAG, "start service with args: $cfg")

      val cfg = cfg ?: Utils.PromoteServiceConfig.load(context)

      // and try to toggle the service to trigger rebind
      with(NotificationsHandlerService) {

        /* Start the notification service once permission has been given. */
        val intent = Intent(context, NotificationsHandlerService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && cfg.foreground == true) {
          Log.i(TAG, "start service foreground")
          context.startForegroundService(intent)
        } else {
          Log.i(TAG, "start service normal")
          context.startService(intent)
        }

        // and try to toggle the service to trigger rebind
        disableServiceSettings(context)
        enableServiceSettings(context)
      }

      return true
    }

    fun startService(context: Context, cfg: Utils.PromoteServiceConfig): Boolean {
      // store the config
      cfg.save(context)
      return internalStartService(context, cfg)
    }

    fun stopService(context: Context): Boolean {
      if (!isServiceRunning(context, NotificationsHandlerService::class.java)) return true

      val intent = Intent(context, NotificationsHandlerService::class.java)
      intent.action = NotificationsHandlerService.ACTION_SHUTDOWN
      context.startService(intent)
      return true
    }



    fun isServiceRunning(context: Context, serviceClass: Class<*>): Boolean {
      return null != getRunningService(context, serviceClass)
    }

    private fun getRunningService(context: Context, serviceClass: Class<*>): ActivityManager.RunningServiceInfo? {
      val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager?
      for (service in manager!!.getRunningServices(Int.MAX_VALUE)) {
        if (serviceClass.name == service.service.className) {
          return service
        }
      }

      return null
    }

    fun registerEventHandle(context: Context, cbId: Long): Boolean {
      context.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
        .edit()
        .putLong(CALLBACK_HANDLE_KEY, cbId)
        .apply()
      return true
    }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "plugin.initialize" -> {
        val cbId = call.arguments<Long?>()!!
        initialize(mContext, cbId)
        return result.success(true)
      }
      "plugin.startService" -> {
        val cfg = Utils.PromoteServiceConfig.fromMap(call.arguments as Map<*, *>)
        return result.success(startService(mContext, cfg))
      }
      "plugin.stopService" -> {
        return result.success(stopService(mContext))
      }
      "plugin.cancelNotification" -> {
        return result.success(stopService(mContext))
      }
      "plugin.cancelNotifications" -> {
        return result.success(stopService(mContext))
      }
      "plugin.hasPermission" -> {
        return result.success(NotificationsHandlerService.permissionGiven(mContext))
      }
      "plugin.openPermissionSettings" -> {
        return result.success(NotificationsHandlerService.openPermissionSettings(mContext))
      }
      "plugin.isServiceRunning" -> {
        return result.success(isServiceRunning(mContext, NotificationsHandlerService::class.java))
      }
      "plugin.registerEventHandle" -> {
        val cbId = call.arguments<Long?>()!!
        registerEventHandle(mContext, cbId)
        return result.success(true)
      }
      // TODO: register handle with filter
      "setFilter" -> {
        // TODO
      }
      else -> result.notImplemented()
    }
  }
}
