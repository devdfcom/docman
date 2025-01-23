package devdf.plugins.docman.methods

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.documentfile.provider.DocumentFile
import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.ActivityMethodBase
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.QueuedMethod
import devdf.plugins.docman.extensions.activityUri
import devdf.plugins.docman.extensions.asChooser
import devdf.plugins.docman.extensions.initialUriByMimeType
import devdf.plugins.docman.extensions.initialUriString
import devdf.plugins.docman.extensions.saveToUri
import devdf.plugins.docman.extensions.toDocumentFile
import devdf.plugins.docman.extensions.toMapResult
import devdf.plugins.docman.extensions.toUri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** This class is responsible for handling the [DocumentFile] activity methods
 * All interactive methods that require the activity context are handled here.
 */
class DocumentFileActivity(
    private val plugin: DocManPlugin,
    private val call: MethodCall,
    override val result: MethodChannel.Result,
) : ActivityMethodBase, QueuedMethod {

    override val meta: DocManMethod = DocManMethod.DocumentFileActivity

    private lateinit var doc: DocumentFile
    private lateinit var action: String

    override fun startActivity() {
        //1. Try to get the document file
        val docUri =
            call.argument<String>("uri") ?: return onError("Invalid arguments, uri is required")
        doc = docUri.toUri().toDocumentFile(plugin.context)
            ?: return onError("Cannot initialize document file, uri is invalid")
        //2. Run proper action
        action = call.argument<String>("action")
            ?: return onError("Invalid arguments, action is required")
        val intent = when (action) {
            "open" -> actionViewIntent()
            "share" -> actionSendIntent()
            "saveTo" -> actionCreateDocumentIntent()
            else -> return onError("Action $action is not supported")
        }

        try {
            plugin.binding?.activity?.startActivityForResult(intent, requestCode.toInt())
        } catch (_: Exception) {
            plugin.queue.finishWithError(requestCode, "no_activity", action, null)
        }
    }

    private fun actionViewIntent(): Intent {
        return Intent(Intent.ACTION_VIEW).apply {
            //Fix for mime type issue, this method has more chances to open the file
            setDataAndTypeAndNormalize(doc.activityUri(plugin.context), doc.type)
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        }.asChooser(call.argument<String>("title"))
    }

    private fun actionSendIntent(): Intent {
        val uri = doc.activityUri(plugin.context)
        return Intent(Intent.ACTION_SEND).apply {
            type = doc.type ?: "*/*"
            //Fix for Permission Denial: opening provider
            clipData = ClipData.newRawUri("", uri)
            putExtra(Intent.EXTRA_STREAM, uri)
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        }.asChooser(call.argument<String>("title"))
    }

    private fun actionCreateDocumentIntent(): Intent {
        val localOnly = call.argument<Boolean>("localOnly") == true
        val initDir = call.argument<String>("initDir")
        return Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_TITLE, doc.name)
            if (localOnly) putExtra(Intent.EXTRA_LOCAL_ONLY, true)
            if (initDir != null) {
                initialUriString(initDir)
            } else initialUriByMimeType(listOf(doc.type ?: "*/*"))
            type = doc.type ?: "*/*"
        }
    }

    override fun onActivityResult(resultCode: Int, data: Intent?): Boolean {
        when (action) {
            "open" -> success(true)
            "share" -> success(true)
            "saveTo" -> if (resultCode == Activity.RESULT_OK) processSaveTo(data) else success(null)
            else -> success(null)
        }

        return true
    }

    private fun processSaveTo(data: Intent?) {
        val deleteSource = call.argument<Boolean>("deleteSource") == true
        if (data != null && data.data != null) {
            CoroutineScope(Dispatchers.IO).launch {
                val newDoc = doc.saveToUri(data.data!!, deleteSource, plugin.context)
                success(newDoc?.toMapResult(plugin.context))
            }
        } else onError("No data returned")

    }


    override fun success(data: Any?) {
        plugin.queue.finishWithSuccess(requestCode, data)
    }

    override fun onError(message: String?, details: Any?) {
        plugin.queue.finishWithError(requestCode, errorCode, message, details)
    }
}