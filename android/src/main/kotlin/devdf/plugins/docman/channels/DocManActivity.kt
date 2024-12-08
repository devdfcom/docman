package devdf.plugins.docman.channels

import android.content.Intent
import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.ActivityBase
import devdf.plugins.docman.definitions.ActivityMethodBase
import devdf.plugins.docman.definitions.DocManChannel
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.EngineBase
import devdf.plugins.docman.methods.DocumentFileActivity
import devdf.plugins.docman.methods.PickActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** This class is responsible for handling the method calls for the activity channel.
 * All interactive methods that require the activity context are handled here.
 */
internal class DocManActivity(private val plugin: DocManPlugin) : EngineBase,
    MethodChannel.MethodCallHandler, ActivityBase {

    private var channel: MethodChannel? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val method = when (DocManMethod.fromMethodName(call.method)) {
            DocManMethod.PickActivity -> PickActivity(plugin, call, result)
            DocManMethod.DocumentFileActivity -> DocumentFileActivity(plugin, call, result)
            else -> null
        }

        if (method == null) return result.notImplemented()
        //2. Adding the method call to the queue & starting the activity
        if (plugin.queue.add(method)) method.startActivity()
    }

    override fun startActivity() {
        plugin.binding?.addActivityResultListener(this)
    }

    override fun stopActivity() {
        plugin.binding?.removeActivityResultListener(this)
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return plugin.queue.methodCast<ActivityMethodBase>(requestCode)
            ?.onActivityResult(resultCode, data) ?: false
    }

    override fun onAttach() {
        if (channel != null) onDetach()

        channel = MethodChannel(plugin.messenger!!, DocManChannel.Activity.channelName)

        channel?.setMethodCallHandler(this)

    }

    override fun onDetach() {
        if (channel == null) return

        channel?.setMethodCallHandler(null)
        channel = null
    }

}