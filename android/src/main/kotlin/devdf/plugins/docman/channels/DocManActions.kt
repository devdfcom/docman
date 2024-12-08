package devdf.plugins.docman.channels

import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.DocManChannel
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.EngineBase
import devdf.plugins.docman.methods.AppDirsAction
import devdf.plugins.docman.methods.DocumentFileAction
import devdf.plugins.docman.methods.PermissionsAction
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

/** This class is used to manage the actions that are available to the plugin
 * This class handle all the actions that are available to the plugin, which
 * are not require Activity lifecycle management.
 */
internal class DocManActions(private val plugin: DocManPlugin) : EngineBase,
    MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        //1. Handling the method call
        val action = when (DocManMethod.fromMethodName(call.method)) {
            DocManMethod.Permissions -> PermissionsAction(plugin, call, result)
            DocManMethod.AppDirs -> AppDirsAction(plugin, call, result)
            DocManMethod.DocumentFileAction -> DocumentFileAction(plugin, call, result)
            else -> null
        }

        if (action == null) return result.notImplemented()
        //2. Adding the method call to the queue
        if (plugin.queue.add(action)) action.oMethodCall()
    }

    override fun onAttach() {
        if (channel != null) onDetach()
        //1. Setting the channel
        channel = MethodChannel(
            plugin.messenger!!,
            DocManChannel.Action.channelName,
            StandardMethodCodec.INSTANCE,
            plugin.messenger!!.makeBackgroundTaskQueue()
        )
        channel!!.setMethodCallHandler(this)
    }

    override fun onDetach() {
        if (channel == null) return

        channel?.setMethodCallHandler(null)
        channel = null
    }
}