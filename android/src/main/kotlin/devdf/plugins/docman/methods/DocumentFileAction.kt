package devdf.plugins.docman.methods

import android.util.Size
import androidx.documentfile.provider.DocumentFile
import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.ActionMethodBase
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.QueuedMethod
import devdf.plugins.docman.extensions.argAsListString
import devdf.plugins.docman.extensions.asFileName
import devdf.plugins.docman.extensions.canCreate
import devdf.plugins.docman.extensions.copyTo
import devdf.plugins.docman.extensions.copyToCache
import devdf.plugins.docman.extensions.deleteDocument
import devdf.plugins.docman.extensions.getBaseName
import devdf.plugins.docman.extensions.getThumbnail
import devdf.plugins.docman.extensions.getThumbnailFile
import devdf.plugins.docman.extensions.isAppDir
import devdf.plugins.docman.extensions.listDocuments
import devdf.plugins.docman.extensions.moveTo
import devdf.plugins.docman.extensions.toDocumentFile
import devdf.plugins.docman.extensions.toMapResult
import devdf.plugins.docman.extensions.toUri
import devdf.plugins.docman.extensions.writeContent
import devdf.plugins.docman.utils.BitmapCompressFormat
import devdf.plugins.docman.utils.DocManFiles
import devdf.plugins.docman.utils.DocManMimeType
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** Used to handle all supported document file actions  */
class DocumentFileAction(
    private val plugin: DocManPlugin,
    private val call: MethodCall,
    override val result: MethodChannel.Result,
) : ActionMethodBase, QueuedMethod {

    override val meta: DocManMethod = DocManMethod.DocumentFileAction

    /// Override the requestCode, to allow multiple actions on different documents
    override val requestCode: String = call.argument<String>("uri") ?: meta.requestCode.toString()
    private lateinit var doc: DocumentFile

    override fun oMethodCall() {
        //1. Try to get the document file
        val docUri =
            call.argument<String>("uri")?.toUri()
                ?: return onError("Invalid arguments, uri is required")
        doc = docUri.toDocumentFile(plugin.context)
            ?: return onError("Cannot initialize document file, uri is invalid")
        //2. Run proper action
        val action = call.argument<String>("action")
            ?: return onError("Invalid arguments, action is required")
        //3. Run the action
        when (action) {
            "get" -> success(doc.toMapResult(plugin.context))
            "read" -> readDocument()
            "createDirectory" -> createDirectory()
            "createFile" -> createFile()
            "list" -> listDocuments()
            "find" -> findFile()
            "cache" -> cacheDocument()
            "copyTo" -> copyTo()
            "moveTo" -> moveTo()
            "thumbnail" -> getThumbnail()
            "thumbnailFile" -> getThumbnail(true)
            "delete" -> CoroutineScope(Dispatchers.IO).launch {
                success(doc.deleteDocument(plugin.context))
            }
//            "rename" -> renameTo()
            else -> onError("Action $action is not supported")
        }

    }

    private fun readDocument() {
        //1. Check if the document is a file
        if (!doc.isFile) return onError("Document is not a file")
        //2. Check if the document is readable
        if (!doc.canRead()) return onError("Document is not readable")
        //3. Get the content
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val bytes =
                    plugin.context.contentResolver.openInputStream(doc.uri)?.use { it.readBytes() }
                success(bytes)
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    private fun createDirectory() {
        //1. Check if the directory is valid
        if (!doc.isDirectory) return onError("Source Document is not a directory")
        //2. Check if directory can create sub directory
        if (!doc.isAppDir(plugin.context) && !doc.canCreate(plugin.context)) {
            return onError("Cannot create sub directory in this directory")
        }
        //3. Check if the name is provided
        val name = call.argument<String>("name")?.takeIf { it.isNotEmpty() }?.let {
            if (doc.isAppDir(plugin.context)) it.asFileName() else it
        } ?: return onError("Invalid or empty directory name")
        //4. Create the directory
        val resultDoc = try {
            doc.createDirectory(name)
        } catch (e: Exception) {
            return onError(e.message)
        }
        //5. Return the result
        success(resultDoc?.toMapResult(plugin.context))
    }

    private fun createFile() {
        val (baseName, extension) = call.argument<String>("name")?.split(".")?.let { list ->
            (list.firstOrNull()?.takeIf { it.isNotEmpty() }?.asFileName()
                ?: DocManFiles.genFileName()) to list.getOrNull(1)
        } ?: (DocManFiles.genFileName() to null)

        //1. Return error if extension is not provided
        if (extension.isNullOrEmpty()) return onError("Extension is required in file name")
        //2. Detect the mime type
        //TODO: what if user wants to use custom extension or mime type? Example: '.bck' -> 'application/backup'
        val mimeType = DocManMimeType.fromExtension(extension)
            ?: return onError("Cannot detect mime type for extension $extension")
        //3. Get the content
        val content = call.argument<ByteArray>("content") ?: return onError("Content is required")
        //4. Check if directory is not app directory and can't create file
        if (!doc.isAppDir(plugin.context) && !doc.canCreate(plugin.context)) {
            return onError("Cannot create file in this directory")
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                //5. Create the file
                val resultDoc = doc.createFile(mimeType, baseName)
                //6. Write the content
                resultDoc?.writeContent(content, plugin.context)
                //7. Return the result
                success(resultDoc?.toMapResult(plugin.context))
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }


    private fun listDocuments() {
        //1. Check if the directory is valid
        if (!doc.isDirectory) return onError("Document is not a directory")
        //2. Get arguments
        val filterTypes = DocManMimeType.combine(
            call.argAsListString("mimeTypes"),
            call.argAsListString("extensions")
        )
        val filterName = call.argument<String>("name")
        //3. Run the list
        CoroutineScope(Dispatchers.IO).launch {
            try {
                //4. List the documents
                success(doc.listDocuments(plugin.context, filterTypes, filterName))
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    private fun findFile() {
        //1. Check if the directory is valid
        if (!doc.isDirectory) return onError("Document is not a directory")
        val name = call.argument<String>("name")
        if (name.isNullOrEmpty()) return onError("Name is required")
        //2. Find the file
        CoroutineScope(Dispatchers.IO).launch {
            try {
                success(doc.findFile(name)?.toMapResult(plugin.context))
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    private fun cacheDocument() {
        //1. Check if the document is a file
        if (!doc.isFile) return onError("Document is not a file")
        //2. Check if we got imageQuality argument
        val imageQuality = call.argument<Int>("imageQuality") ?: 100
        //3. Cache the document
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val resultPath = doc.copyToCache(plugin.context, imageQuality)
                success(resultPath)
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    private fun copyTo() {
        //1. Validate the source document & destination directory
        val destDoc = validateCopyMove() ?: return
        //2. Check new name
        val name = call.argument<String>("name")?.substringBefore(".")?.asFileName()
            ?: doc.getBaseName()
        //3. Copy document to destination directory
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val result = doc.copyTo(destDoc, name, plugin.context)
                success(result?.toMapResult(plugin.context))
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    private fun moveTo() {
        //1. Validate the source document & destination directory
        val destDoc = validateCopyMove() ?: return
        //2. Check new name
        val name = call.argument<String>("name")?.substringBefore(".")?.asFileName()
            ?: doc.getBaseName()
        //3. Move document to destination directory
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val result = doc.moveTo(destDoc, name, plugin.context)
                success(result?.toMapResult(plugin.context))
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    private fun validateCopyMove(): DocumentFile? {
        //1. Validate the source document
        if (!doc.isFile) return onError("Source Document is not a file").let { null }
        if (!doc.canRead()) return onError("Source Document is not readable").let { null }
        if (doc.type == null) return onError("Source Document mime type is not detected").let { null }
        //2. Validate the destination directory
        val destUri = call.argument<String>("to")?.toUri()
            ?: return onError("Destination uri is required").let { null }

        val destDoc = destUri.toDocumentFile(plugin.context)
            ?: return onError("Cannot initialize destination directory, uri is invalid").let { null }

        return if (destDoc.canCreate(plugin.context) || destDoc.isAppDir(plugin.context)) {
            destDoc
        } else onError("Destination directory is not writable").let { null }
    }

    private fun getThumbnail(asFile: Boolean = false) {
        //1. Check if the document is a file
        if (!doc.isFile) return onError("Document is not a file")
        //2. Check if we got imageQuality argument
        val quality = call.argument<Int>("imageQuality") ?: 100
        val size = Size(
            call.argument<Int>("width") ?: 256,
            call.argument<Int>("height") ?: 256
        )
        val format = when {
            call.argument<Boolean>("png") == true -> BitmapCompressFormat.PNG
            call.argument<Boolean>("webp") == true -> BitmapCompressFormat.WEBP
            else -> BitmapCompressFormat.JPEG
        }
        //3. Run the thumbnail
        CoroutineScope(Dispatchers.IO).launch {
            try {
                if (asFile) {
                    success(doc.getThumbnailFile(size, quality, format, plugin.context))
                } else {
                    success(doc.getThumbnail(size, quality, format, plugin.context)?.toMap())
                }
            } catch (e: Exception) {
                onError(e.message)
            }
        }
    }

    /** Method renameTo - almost not working, only errors, due to different providers mechanisms */
//    private fun renameTo() {
//        //1. Get the new name
//        val newName = call.argument<String>("name") ?: return success(null)
//        //2. Check if name is empty string
//        if (newName.isEmpty()) return success(null)
//        //3. Check if the name is the same
//        if (newName == doc.name) return success(doc.toMapResult(plugin.context))
//        //4. Check for proper flag
//        if (!doc.canRename(plugin.context)) return success(null)
//
//        try {
//            val result = doc.renameTo(newName)
//            success(if (result) doc.toMapResult(plugin.context) else null)
//        } catch (e: Exception) {
//            onError(e.message)
//        }
//    }

    override fun success(data: Any?) {
        plugin.queue.finishWithSuccess(requestCode, data)
    }

    override fun onError(message: String?, details: Any?) {
        plugin.queue.finishWithError(requestCode, errorCode, message, details)
    }

}