package devdf.plugins.docman

import android.content.res.AssetFileDescriptor
import android.database.Cursor
import android.database.MatrixCursor
import android.graphics.Point
import android.net.Uri
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Root
import android.provider.DocumentsProvider
import devdf.plugins.docman.extensions.getMimeTypeByExtension
import devdf.plugins.docman.extensions.getThumbnailName
import devdf.plugins.docman.extensions.isVideo
import devdf.plugins.docman.utils.DocManFiles
import devdf.plugins.docman.utils.DocManProviderSettings
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.text.Normalizer
import java.util.Locale

/** DocManDocumentsProvider - converts local app folder to DocumentsProvider */
class DocManDocumentsProvider : DocumentsProvider() {
    /** The root directory of the provider */
    private lateinit var rootDirectory: File

    /** The name of the application */
    private lateinit var applicationName: String

    /** The settings for the provider */
    private lateinit var settings: DocManProviderSettings

    companion object {
        /** The document ID of the root directory */
        const val ROOT_DOC_ID: String = "DocManDocumentsProviderRoot"

        /** The authority of the provider */
        lateinit var authority: String

        fun documentUri(documentId: String): Uri =
            DocumentsContract.buildDocumentUri(authority, documentId)

        /** The child documents URI for a parent document */
        fun childDocumentsUri(parentDocumentId: String): Uri =
            DocumentsContract.buildChildDocumentsUri(authority, parentDocumentId)
    }

    /** Called when the provider is created */
    override fun onCreate(): Boolean {
        //1. Try to load the provider settings from the assets provider.json file
        runCatching {
            val json: String =
                context!!.assets.open("flutter_assets/assets/provider.json").use { input ->
                    BufferedInputStream(input).use { it.readBytes().toString(Charsets.UTF_8) }
                }
            settings = DocManProviderSettings.fromJson(json)
            rootDirectory = DocManFiles.providerDir(settings.rootPath, context!!)
            applicationName =
                context!!.applicationInfo.loadLabel(context!!.packageManager).toString()
            authority = context!!.packageName + ".docman.documents"
        }.getOrNull() ?: return false

        //Check if settings are not yet initialized
        return ::settings.isInitialized
    }

    /** Describes the root of the provider */
    override fun queryRoots(projection: Array<out String>?): Cursor {
        if (!::settings.isInitialized) {
            return MatrixCursor(projection ?: arrayOf())
        }

        //1. Setting up the cursor
        val cursor = MatrixCursor(projection ?: settings.defaultRootProjection())

        cursor.newRow().apply {
            add(Root.COLUMN_ROOT_ID, "root")
            add(Root.COLUMN_DOCUMENT_ID, ROOT_DOC_ID)
            add(Root.COLUMN_MIME_TYPES, settings.mimeTypes)
            add(Root.COLUMN_FLAGS, settings.getRootFlags())
            add(Root.COLUMN_ICON, context!!.applicationInfo.icon)
            add(Root.COLUMN_TITLE, settings.providerName ?: applicationName)
            add(Root.COLUMN_SUMMARY, settings.providerSubtitle)
        }

        //2. Notify the system that the cursor has changed & return the cursor
        return cursor.apply {
            setNotificationUrl(DocumentsContract.buildRootsUri(authority))
        }
    }

    /** Queries the recent documents */
    override fun queryRecentDocuments(rootId: String, projection: Array<out String>?): Cursor {
        if (!::settings.isInitialized) {
            return MatrixCursor(projection ?: arrayOf())
        }

        val result = MatrixCursor(projection ?: settings.defaultDocumentProjection())

        getFile(rootId).walkTopDown()
            .filter { it.isFile }
            .map { it to it.lastModified() }
            .sortedByDescending { it.second }
            .take(settings.maxRecentFiles)
            .forEach { (file, _) -> includeFile(result, null, file) }

        return result
    }

    override fun querySearchDocuments(
        rootId: String,
        query: String,
        projection: Array<String>?
    ): Cursor {
        if (!::settings.isInitialized) {
            return MatrixCursor(projection ?: arrayOf())
        }

        val result = MatrixCursor(projection ?: settings.defaultDocumentProjection())
        val parent = getFile(rootId)
        val normalQuery =
            Normalizer.normalize(query.lowercase(Locale.getDefault()), Normalizer.Form.NFD)

        parent.walkTopDown().asSequence()
            .filter { it.isFile }
            .map {
                it to Normalizer.normalize(
                    it.name.lowercase(Locale.getDefault()),
                    Normalizer.Form.NFD
                )
            }
            .filter { (_, fileName) -> fileName.contains(normalQuery) }
            .take(settings.maxSearchResults)
            .forEach { (file, _) -> includeFile(result, null, file) }

        return result
    }

    override fun queryChildDocuments(
        parentDocumentId: String?,
        projection: Array<out String>?,
        sortOrder: String?
    ): Cursor {
        if (!::settings.isInitialized) {
            return MatrixCursor(projection ?: arrayOf())
        }

        var cursor = MatrixCursor(projection ?: settings.defaultDocumentProjection())

        val parent = getFile(parentDocumentId!!)
        for (file in parent.listFiles()!!)
            cursor = includeFile(cursor, null, file)

        // Notify the system that the cursor has changed
        return cursor.apply {
            setNotificationUrl(childDocumentsUri(parentDocumentId))
        }
    }

    override fun queryDocument(documentId: String?, projection: Array<out String>?): Cursor {
        if (!::settings.isInitialized) {
            return MatrixCursor(projection ?: arrayOf())
        }

        val cursor = MatrixCursor(projection ?: settings.defaultDocumentProjection())
        return includeFile(cursor, documentId, null)
    }

    override fun isChildDocument(parentDocumentId: String?, documentId: String?): Boolean {
        val parent = getFile(parentDocumentId!!)
        val file = getFile(documentId!!)
        return file.parentFile == parent
    }

    override fun createDocument(
        parentDocumentId: String?,
        mimeType: String?,
        displayName: String
    ): String = File(getFile(parentDocumentId!!), displayName).apply {
        val success = when (mimeType) {
            DocumentsContract.Document.MIME_TYPE_DIR -> mkdir()
            else -> createNewFile()
        }
        if (!success) throw FileSystemException(this)
        notifyChange(childDocumentsUri(parentDocumentId))
    }.let { getDocumentId(it) }

    override fun deleteDocument(documentId: String?) {
        getFile(documentId!!).apply {
            if (!deleteRecursively()) throw FileSystemException(this)
            /// Notify the system that the document has been deleted
            parentFile?.let {
                notifyChange(childDocumentsUri(getDocumentId(it)))
            }
        }
    }

    override fun removeDocument(documentId: String, parentDocumentId: String?) {
        val parent = getFile(parentDocumentId!!)
        val file = getFile(documentId)

        if (parent == file || file.parentFile == null || file.parentFile!! == parent) {
            if (!file.deleteRecursively()) throw FileSystemException(file)
            /// Notify the system that the document has been deleted
            notifyChange(childDocumentsUri(parentDocumentId))
        } else {
            throw FileNotFoundException("Couldn't delete document with ID '$documentId'")
        }
    }

    override fun renameDocument(documentId: String?, displayName: String?): String {
        if (displayName == null)
            throw FileNotFoundException("Couldn't rename document '$documentId' as the new name is null")

        val sourceFile = getFile(documentId!!)
        val sourceParentFile = sourceFile.parentFile
            ?: throw FileNotFoundException("Couldn't rename document '$documentId' as it has no parent")
        val destFile = sourceParentFile.resolve(displayName)

        try {
            if (!sourceFile.renameTo(destFile))
                throw FileNotFoundException("Couldn't rename document from '${sourceFile.name}' to '${destFile.name}'")
        } catch (e: Exception) {
            throw FileNotFoundException("Couldn't rename document from '${sourceFile.name}' to '${destFile.name}': ${e.message}")
        }

        return getDocumentId(destFile)
    }

    override fun copyDocument(sourceDocumentId: String, targetParentDocumentId: String?): String {
        val parent = getFile(targetParentDocumentId!!)
        val oldFile = getFile(sourceDocumentId)
        val newFile = parent.resolveWithoutConflict(oldFile.name)

        try {
            if (!(newFile.createNewFile() && newFile.setWritable(true) && newFile.setReadable(true)))
                throw IOException("Couldn't create new file")

            FileInputStream(oldFile).use { inStream ->
                FileOutputStream(newFile).use { outStream ->
                    inStream.copyTo(outStream)
                }
            }
        } catch (e: IOException) {
            throw FileNotFoundException("Couldn't copy document '$sourceDocumentId': ${e.message}")
        }

        return getDocumentId(newFile)
    }

    override fun moveDocument(
        sourceDocumentId: String,
        sourceParentDocumentId: String?,
        targetParentDocumentId: String?
    ): String {
        try {
            val newDocumentId = copyDocument(
                sourceDocumentId, sourceParentDocumentId!!,
                targetParentDocumentId
            )
            removeDocument(sourceDocumentId, sourceParentDocumentId)
            return newDocumentId
        } catch (e: FileNotFoundException) {
            throw FileNotFoundException("Couldn't move document '$sourceDocumentId'")
        }
    }


    override fun openDocument(
        documentId: String?,
        mode: String?,
        signal: CancellationSignal?
    ): ParcelFileDescriptor {
        val file = documentId?.let { getFile(it) }
        val accessMode = ParcelFileDescriptor.parseMode(mode)
        return ParcelFileDescriptor.open(file, accessMode)
    }

    override fun openDocumentThumbnail(
        documentId: String?,
        sizeHint: Point,
        signal: CancellationSignal?
    ): AssetFileDescriptor {
        //1. Get the file for the document ID
        val file = getFile(documentId!!)
        //1.1. Get the thumbnail name for the document
        val thumbName = "${sizeHint.x}x${sizeHint.y}_${documentId}"
        //2. Get the thumbnail file for the document
        val thumbFile = File(
            DocManFiles.thumbnailsCacheDir(context!!),
            file.getThumbnailName(thumbName)
        )
        //3. If the thumbnail doesn't exist and the file can be used to generate a thumbnail
        if (!thumbFile.exists() && (file.isVideo() || file.extension == "pdf")) {
            DocManFiles.getThumbnailForFile(file, thumbFile, sizeHint, context!!)
        }
        //4. Return the thumbnail file
        return AssetFileDescriptor(
            ParcelFileDescriptor.open(
                if (thumbFile.exists() && thumbFile.length() != 0L) thumbFile else file,
                ParcelFileDescriptor.MODE_READ_ONLY
            ),
            0,
            AssetFileDescriptor.UNKNOWN_LENGTH
        )
    }

    /**
     * @return The [File] that corresponds to the document ID supplied by [getDocumentId]
     */
    private fun getFile(documentId: String): File {
        return when (documentId) {
            "root", ROOT_DOC_ID -> rootDirectory
            else -> rootDirectory.resolve(documentId).apply {
                if (!exists()) throw FileNotFoundException("Couldn't find document with ID '$documentId'")
            }
        }
    }

    /**
     * @return A unique ID for the provided [File]
     */
    private fun getDocumentId(file: File): String {
        return if (file == rootDirectory) ROOT_DOC_ID else file.relativeTo(rootDirectory).path
    }

    /**
     * @return A new [File] with a unique name based off the supplied [name],
     * not conflicting with any existing file
     */
    private fun File.resolveWithoutConflict(name: String): File {
        var file = resolve(name)
        if (file.exists()) {
            var nameNumber = 1
            val extension = name.substringAfterLast('.')
            val baseName = name.substringBeforeLast('.')
            while (file.exists())
                file = if (extension == baseName) {
                    resolve("$baseName ($nameNumber++)")
                } else {
                    resolve("$baseName (${nameNumber++}).$extension")
                }
        }
        return file
    }

    private fun copyDocument(
        sourceDocumentId: String, sourceParentDocumentId: String,
        targetParentDocumentId: String?
    ): String {
        if (!isChildDocument(sourceParentDocumentId, sourceDocumentId))
            throw FileNotFoundException("Couldn't copy document '$sourceDocumentId' as its parent is not '$sourceParentDocumentId'")

        return copyDocument(sourceDocumentId, targetParentDocumentId)
    }


    private fun includeFile(cursor: MatrixCursor, documentId: String?, file: File?): MatrixCursor {
        val docID = documentId ?: file?.let { getDocumentId(it) }
        val docFile = file ?: getFile(documentId!!)

        cursor.newRow().apply {
            add(DocumentsContract.Document.COLUMN_DOCUMENT_ID, docID)
            add(DocumentsContract.Document.COLUMN_MIME_TYPE, getTypeForFile(docFile))
            add(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                if (docFile == rootDirectory) applicationName else docFile.name
            )
            add(DocumentsContract.Document.COLUMN_LAST_MODIFIED, docFile.lastModified())
            add(DocumentsContract.Document.COLUMN_SIZE, docFile.length())
            add(DocumentsContract.Document.COLUMN_FLAGS, settings.getDocumentFlags(docFile))
            add(
                DocumentsContract.Document.COLUMN_ICON,
                if (docFile == rootDirectory) context!!.applicationInfo.icon else null
            )
            add(DocumentsContract.Document.COLUMN_SUMMARY, null)
        }

        return cursor
    }

    private fun getTypeForFile(file: File): Any = if (file.isDirectory) {
        DocumentsContract.Document.MIME_TYPE_DIR
    } else {
        file.name.getMimeTypeByExtension()
    }

    private fun MatrixCursor.setNotificationUrl(uri: Uri) =
        setNotificationUri(context!!.contentResolver, uri)

    private fun notifyChange(uri: Uri) = context!!.contentResolver.notifyChange(uri, null)
}