package devdf.plugins.docman.channels

import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.DocManChannel
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.EventMethodBase
import devdf.plugins.docman.definitions.EventsBase
import devdf.plugins.docman.methods.DocumentFileEvent
import devdf.plugins.docman.methods.PermissionsEvents
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class DocManEvents(private val plugin: DocManPlugin) : EventsBase {

    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var job: Job? = null
    private var block: EventMethodBase? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        //1. Setting the event sink
        eventSink = events
        //2. Determine the event
        val call = MethodCall("eventCall", arguments)
        val method = call.argument<String>("method")
        //3 Validate the method
        if (method == null) {
            eventSink?.error("invalid_args", "Method argument is required", null)
            return
        }
        //4. Setting scope block
        block = when (DocManMethod.fromMethodName(method)) {
            DocManMethod.DocumentFileEvent -> DocumentFileEvent(plugin, call, eventSink)
            DocManMethod.PermissionsEvent -> PermissionsEvents(plugin, call, eventSink)
            //Return not implemented error
            else -> {
                eventSink?.error("not_implemented", "Method $method is not implemented", null)
                return
            }
        }

        //5. Setting the job
        job = CoroutineScope(Dispatchers.IO).launch { block!!.onListen() }
        //6. Setting the job completion
        job?.invokeOnCompletion {
            job = null
            block = null
        }
    }

    override fun onCancel(arguments: Any?) {
        //1. Check if the block is set & run onCancel method
        block?.onCancel(arguments)
        //2. Cancel the job
        job?.cancel()
        //3. Clear the block
        eventSink = null
    }

    override fun onAttach() {
        if (eventChannel != null) onDetach()

        eventChannel = EventChannel(plugin.messenger, DocManChannel.Events.channelName)
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetach() {
        if (eventChannel == null) return

        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }
}