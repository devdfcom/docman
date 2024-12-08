package devdf.plugins.docman.methods

import android.net.Uri
import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.ActionMethodBase
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.QueuedMethod
import devdf.plugins.docman.extensions.persistedPermissions
import devdf.plugins.docman.extensions.toDocumentFile
import devdf.plugins.docman.extensions.toDocumentMap
import devdf.plugins.docman.extensions.toMap
import devdf.plugins.docman.extensions.toUri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Used to handle all supported persisted permissions actions  */
class PermissionsAction(
    private val plugin: DocManPlugin,
    call: MethodCall,
    override val result: MethodChannel.Result,
) : ActionMethodBase, QueuedMethod {

    override val meta: DocManMethod = DocManMethod.Permissions

    private val action: String? = call.argument<String>("action")

    private val uri: Uri? = call.argument<String>("uri")?.toUri()

    private val dirs: Boolean = call.argument<Boolean>("dirs") ?: true

    private val files: Boolean = call.argument<Boolean>("files") ?: true

    override fun oMethodCall() {
        //Validate the action
        when (action) {
            "release" -> release()
            "status" -> status()
            "list" -> list()
            "listDocuments" -> listDocuments()
            "releaseAll" -> releaseAll()
            "validateList" -> validateList()
            else -> plugin.queue.finishNotImplemented(requestCode)
        }
    }

    private fun release() {
        if (uri == null) return onError("Invalid arguments, uri is required")
        try {
            //Have to check through document, if it's directory, document uri requires rebuild.
            val doc = uri.toDocumentFile(plugin.context)
                ?: return onError("Cannot initialize document file, uri is invalid")

            doc.persistedPermissions(plugin.context)?.let { plugin.permissions.release(it) }
        } catch (e: Exception) {
            onError(e.message)
            return
        } finally {
            success(true)
        }
    }

    private fun releaseAll() {
        try {
            plugin.permissions.releaseAll()
        } catch (e: Exception) {
            onError(e.message)
            return
        } finally {
            success(true)
        }
    }

    /** Check the status of the persisted permission. */
    private fun status() {
        if (uri == null) return onError("Invalid arguments, uri is required")
        try {
            //Have to check through document, if it's directory, document uri requires rebuild.
            val doc = uri.toDocumentFile(plugin.context)
                ?: return onError("Cannot initialize document file, uri is invalid")

            success(doc.persistedPermissions(plugin.context)?.toMap())
        } catch (e: Exception) {
            onError(e.message)
        }
    }

    /** List all the persisted permissions. */
    private fun list() = success(plugin.permissions.getAll(dirs, files).map { it.toMap() })

    /** List all the persisted documents. */
    private fun listDocuments() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                //1. Get permissions
                val perms = withContext(Dispatchers.IO) { plugin.permissions.getAll(dirs, files) }
                //2. Get all the documents concurrently
                val docs = perms.map { perm ->
                    async(Dispatchers.IO) {
                        val doc = perm.uri.toDocumentMap(plugin.context)
                        //2.1. Release the permission if the document is null
                        if (doc == null) plugin.permissions.release(perm)
                        doc
                    }
                }.awaitAll()
                success(docs.filterNotNull())
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    /** Release all permissions for uris which are not valid documents any more. */
    private fun validateList() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                plugin.permissions.getAll(dirs, files).forEach {
                    if (it.uri.toDocumentFile(plugin.context) == null) {
                        plugin.permissions.release(it)
                    }
                }
                success(true)
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }


    override fun success(data: Any?) {
        plugin.queue.finishWithSuccess(requestCode, data)
    }

    override fun onError(message: String?, details: Any?) {
        plugin.queue.finishWithError(requestCode, errorCode, message, details)
    }
}