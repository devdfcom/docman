package devdf.plugins.docman.methods

import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.EventMethodBase
import devdf.plugins.docman.extensions.toDocumentMap
import devdf.plugins.docman.extensions.toMap
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class PermissionsEvents(
    private val plugin: DocManPlugin,
    private val call: MethodCall,
    private val sink: EventChannel.EventSink?,
) : EventMethodBase {

    override val meta: DocManMethod = DocManMethod.PermissionsEvent

    private val dirs = call.argument<Boolean>("dirs") ?: true
    private val files = call.argument<Boolean>("files") ?: true

    override suspend fun onListen() {
        when (val action = call.argument<String>("action")) {
            "listStream" -> listStream()
            "listDocumentsStream" -> listStream(true)
            null -> onError("Argument action is required", null)
            else -> onError("Action $action is not implemented", null)
        }
        /// Notify the end of the stream
        onEnd()
    }

    private suspend fun listStream(asDoc: Boolean = false) {
        try {
            plugin.permissions.getAll(dirs, files).forEach {
                val data = if (asDoc) {
                    it.uri.toDocumentMap(plugin.context).also { doc ->
                        //Release the permission if the document is null
                        if (doc == null) plugin.permissions.release(it)
                    }
                } else it.toMap()

                data?.let { onSuccess(data) }
            }
        } catch (e: Exception) {
            onError(e.message, null)
        }
    }


    override suspend fun onSuccess(data: Any?) {
        withContext(Dispatchers.Main) { sink?.success(data) }
    }

    override suspend fun onError(message: String?, details: Any?) {
        withContext(Dispatchers.Main) { sink?.error(errorCode, message, details) }
    }

    override suspend fun onEnd() {
        withContext(Dispatchers.Main) { sink?.endOfStream() }
    }

    override fun onCancel(arguments: Any?) {}
}