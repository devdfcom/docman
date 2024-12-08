package devdf.plugins.docman.methods

import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.EventMethodBase
import devdf.plugins.docman.extensions.argAsListString
import devdf.plugins.docman.extensions.isMimeTypeAllowed
import devdf.plugins.docman.extensions.nameContains
import devdf.plugins.docman.extensions.toDocumentFile
import devdf.plugins.docman.extensions.toMapResult
import devdf.plugins.docman.extensions.toUri
import devdf.plugins.docman.utils.DocManFiles
import devdf.plugins.docman.utils.DocManMimeType
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** This class is responsible for handling the `DocumentFile` event methods (streams) */
class DocumentFileEvent(
    private val plugin: DocManPlugin,
    private val call: MethodCall,
    private val sink: EventChannel.EventSink?,
) : EventMethodBase {

    override val meta: DocManMethod = DocManMethod.DocumentFileEvent

    private val start = call.argument<Int>("start") ?: 0
    override suspend fun onListen() {
        when (val event = call.argument<String>("event")) {
            "readAsString" -> readAsString()
            "readAsBytes" -> readAsBytes()
            "listStream" -> listStream()
            null -> onError("Argument event is required", null)
            else -> onError("Event $event is not implemented", null)
        }
        /// Notify the end of the stream
        onEnd()
    }

    /// This method reads the content of the uri as a string
    private suspend fun readAsString() {
        val uri = call.argument<String>("uri")?.toUri()
            ?: return onError("Argument uri is required", null)
        val bufferSize = call.argument<Int>("buffer") ?: DEFAULT_BUFFER_SIZE
        val charsetName = call.argument<String>("charset") ?: "UTF-8"

        try {
            DocManFiles.streamUriAsString(
                uri,
                bufferSize,
                start,
                charsetName,
                plugin.context
            ) { onSuccess(it) }
        } catch (e: Exception) {
            onError(e.message, null)
        }
    }

    private suspend fun readAsBytes() {
        val uri = call.argument<String>("uri")?.toUri()
            ?: return onError("Argument uri is required", null)
        val bufferSize = call.argument<Int>("buffer") ?: DEFAULT_BUFFER_SIZE
        try {
            DocManFiles.streamUriAsBytes(
                uri,
                bufferSize,
                start,
                plugin.context
            ) { onSuccess(it) }
        } catch (e: Exception) {
            onError(e.message, null)
        }
    }

    private suspend fun listStream() {
        //1. Convert string uri to Uri
        val uri = call.argument<String>("uri")?.toUri()
            ?: return onError("Argument uri is required", null)
        //2. Get the document file from the uri
        val doc = uri.toDocumentFile(plugin.context)
            ?: return onError("Cannot initialize document file, uri is invalid", null)
        //3. Check if the directory is valid
        if (!doc.isDirectory) return onError("Document is not a directory")
        //4. Get arguments
        val filterTypes = DocManMimeType.combine(
            call.argAsListString("mimeTypes"),
            call.argAsListString("extensions")
        )
        val filterName = call.argument<String>("name")

        try {
            doc.listFiles().forEach {
                if (it.isMimeTypeAllowed(filterTypes) && it.nameContains(filterName ?: "")) {
                    onSuccess(it.toMapResult(plugin.context))
                }
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