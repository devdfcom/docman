package devdf.plugins.docman.utils

import android.provider.DocumentsContract
import android.provider.DocumentsContract.Root
import devdf.plugins.docman.extensions.canThumbnail
import java.io.File

data class DirectoryFlags(
    val create: Boolean,
    val delete: Boolean,
    val move: Boolean,
    val rename: Boolean,
    val copy: Boolean,
) {
    companion object {
        fun fromJson(resultMap: Map<String, Any?>?): DirectoryFlags = DirectoryFlags(
            create = resultMap?.get("create") as? Boolean != false,
            delete = resultMap?.get("delete") as? Boolean != false,
            move = resultMap?.get("move") as? Boolean != false,
            rename = resultMap?.get("rename") as? Boolean != false,
            copy = resultMap?.get("copy") as? Boolean != false,
        )
    }
}

data class FileFlags(
    val write: Boolean,
    val delete: Boolean,
    val move: Boolean,
    val rename: Boolean,
    val copy: Boolean,
    val thumbnail: Boolean,
) {
    companion object {
        fun fromJson(resultMap: Map<String, Any?>?): FileFlags = FileFlags(
            write = resultMap?.get("write") as? Boolean != false,
            delete = resultMap?.get("delete") as? Boolean != false,
            move = resultMap?.get("move") as? Boolean != false,
            rename = resultMap?.get("rename") as? Boolean != false,
            copy = resultMap?.get("copy") as? Boolean != false,
            thumbnail = resultMap?.get("thumbnail") as? Boolean != false,
        )
    }
}

/** Settings for the DocumentsProvider */
class DocManProviderSettings(
    val rootPath: String,
    val providerName: String?,
    val providerSubtitle: String?,
    val mimeTypes: String?,
    val showInSystemUI: Boolean,
    val supportRecent: Boolean,
    val supportSearch: Boolean,
    val maxRecentFiles: Int,
    val maxSearchResults: Int,
    val directoryFlags: DirectoryFlags,
    val fileFlags: FileFlags,
) {

    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromJson(json: String): DocManProviderSettings {
            //1. Convert json to map
            val map = DocManFiles.jsonToMap(json)
            //2. Collect supported mime types
            val mimeTypes = DocManMimeType.combine(
                map["mimeTypes"] as? List<String>,
                map["extensions"] as? List<String>,
                true
            ).takeIf { it.isNotEmpty() }?.joinToString("\n")
            //3. Get the directory & file flags
            val dirFlags = DirectoryFlags.fromJson(map["directories"] as? Map<String, Any?>)
            val fileFlags = FileFlags.fromJson(map["files"] as? Map<String, Any?>)
            //4. Return the settings
            return DocManProviderSettings(
                rootPath = map["rootPath"] as? String
                    ?: throw IllegalArgumentException("DocumentsProvider Root path is missing"),
                providerName = map["providerName"] as? String,
                providerSubtitle = map["providerSubtitle"] as? String,
                mimeTypes = mimeTypes,
                showInSystemUI = map["showInSystemUI"] as? Boolean != false,
                supportRecent = map["supportRecent"] as? Boolean != false,
                supportSearch = map["supportSearch"] as? Boolean != false,
                maxRecentFiles = map["maxRecentFiles"] as? Int ?: 15,
                maxSearchResults = map["maxSearchResults"] as? Int ?: 10,
                directoryFlags = dirFlags,
                fileFlags = fileFlags,
            )
        }
    }

    fun getRootFlags(): Int {
        //1. Set the flags, first set the local only flag due to the nature of the provider
        var flags = Root.FLAG_LOCAL_ONLY or Root.FLAG_SUPPORTS_IS_CHILD
        //2. Add the flags based on the settings
        if (directoryFlags.create) {
            flags = flags or Root.FLAG_SUPPORTS_CREATE
        }
        if (supportRecent) {
            flags = flags or Root.FLAG_SUPPORTS_RECENTS
        }
        if (supportSearch) {
            flags = flags or Root.FLAG_SUPPORTS_SEARCH
        }
        if (!showInSystemUI && DocManBuild.supportsRootEmptyFlag()) {
            flags = flags or Root.FLAG_EMPTY
        }

        return flags
    }

    /** Get the document flags by file type & settings */
    fun getDocumentFlags(file: File): Int = if (file.isDirectory) {
        getDirectoryFlags(file)
    } else {
        getDocumentFileFlags(file)
    }

    /** Get the flags for the directory */
    private fun getDirectoryFlags(file: File): Int {
        var flags = 0
        if (directoryFlags.create && file.canWrite()) {
            flags = flags or DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE
        }
        if (directoryFlags.delete) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_DELETE
        }
        if (directoryFlags.move && DocManBuild.supportsMoveCopyFlag()) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_MOVE
        }
        if (directoryFlags.copy && DocManBuild.supportsMoveCopyFlag()) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_COPY
        }
        if (directoryFlags.rename) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_RENAME
        }

        return flags
    }

    /**  Get the flags for the document file (file, not directory) */
    private fun getDocumentFileFlags(file: File): Int {
        var flags = 0
        if (fileFlags.write) {
            flags = DocumentsContract.Document.FLAG_SUPPORTS_WRITE
        }
        if (fileFlags.delete) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_DELETE
        }
        if (fileFlags.move && DocManBuild.supportsMoveCopyFlag()) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_MOVE
        }
        if (fileFlags.move && DocManBuild.supportsMoveCopyFlag()) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_COPY
        }
        if (fileFlags.rename) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_RENAME
        }
        if (fileFlags.thumbnail && file.canThumbnail()) {
            flags = flags or DocumentsContract.Document.FLAG_SUPPORTS_THUMBNAIL
        }

        return flags
    }

    fun defaultRootProjection(): Array<String> = arrayOf(
        Root.COLUMN_ROOT_ID,
        Root.COLUMN_DOCUMENT_ID,
        Root.COLUMN_MIME_TYPES,
        Root.COLUMN_FLAGS,
        Root.COLUMN_ICON,
        Root.COLUMN_TITLE,
        Root.COLUMN_SUMMARY,
    )

    fun defaultDocumentProjection(): Array<String> = arrayOf(
        DocumentsContract.Document.COLUMN_DOCUMENT_ID,
        DocumentsContract.Document.COLUMN_MIME_TYPE,
        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        DocumentsContract.Document.COLUMN_SIZE,
        DocumentsContract.Document.COLUMN_FLAGS,
        DocumentsContract.Document.COLUMN_ICON,
        DocumentsContract.Document.COLUMN_SUMMARY,
    )
}