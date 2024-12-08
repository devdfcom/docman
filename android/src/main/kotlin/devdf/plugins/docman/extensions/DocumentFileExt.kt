package devdf.plugins.docman.extensions

import android.content.Context
import android.content.Intent
import android.content.UriPermission
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Size
import android.webkit.MimeTypeMap
import androidx.documentfile.provider.DocumentFile
import devdf.plugins.docman.utils.BitmapCompressFormat
import devdf.plugins.docman.utils.DocManFiles
import devdf.plugins.docman.utils.DocManMedia
import devdf.plugins.docman.utils.DocumentThumbnail
import java.io.FileNotFoundException


/** This extension is used to convert a [DocumentFile] to a [Map] result
 *
 * @param context The context of the application
 * @return `null` if the [DocumentFile] is not a file or directory, otherwise
 * a [Map] which contains the following keys:
 * - name: The name of the file or directory
 * - type: The mimeType of the file or `directory` if it is a directory
 * - uri: The URI of the `DocumentFile` or the `tree URI` if it is a directory
 * - size: The size of the file or the count of files in the directory
 * - lastModified: The last modified date of the file or directory
 * - exists: `true` if the file or directory exists, otherwise `false`
 * - canRead: `true` if the file or directory can be read, otherwise `false`
 * - canWrite: `true` if the file or directory can be written to, otherwise `false`
 * - canDelete: `true` if the file or directory can be deleted, otherwise `false`
 * - canCreate: `true` if the directory can create documents, otherwise `false`
 * - canThumbnail: `true` if the file has thumbnail, otherwise `false`
 */
fun DocumentFile.toMapResult(context: Context): Map<String, Any?>? {
    return when {
        isDirectory || isFile -> mapOf(
            "name" to name,
            "type" to when {
                isDirectory -> "directory"
                else -> type
            },
            "uri" to uri.toString(),
            "size" to when {
                //If this is a directory, then the size is the count of files in the directory
                isDirectory -> listFiles().size
                else -> length()
            },
            "lastModified" to lastModified(),
            "exists" to exists(),
            "canRead" to canRead(),
//            "isPersisted" to (persistedPermissions(context) != null),
        ) + getFlagsMap(context)

        else -> null
    }
}

fun DocumentFile.getFlagsMap(context: Context): Map<String, Boolean> {
    //We can get proper flags only if this DocumentFile has Document URI
    //If documentFile was initiated with [content://media/external/file/106] etc,
    //then it throws error
    if (!uri.isDocumentUri(context)) {
        val appFile = isAppFile(context)
        val appDirectory = isAppDir(context)

        return mapOf(
            "canWrite" to appFile,
            "canDelete" to appFile,
            "canCreate" to appDirectory,
            "canThumbnail" to (appFile && canThumbnailAlternate(context)),
        )
    }

    val flags = flags(context)
    val canWrite =
        if (isDirectory) canWrite() else isWritable(context) && (flags and DocumentsContract.Document.FLAG_SUPPORTS_WRITE != 0)
    val canDelete =
        if (isAppFile(context)) true else flags and DocumentsContract.Document.FLAG_SUPPORTS_DELETE != 0
    val canCreate = flags and DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE != 0
    val canThumbnail =
        (flags and DocumentsContract.Document.FLAG_SUPPORTS_THUMBNAIL != 0)
                || canThumbnailAlternate(context)

    return mapOf(
        "canWrite" to canWrite,
        "canDelete" to canDelete,
        "canCreate" to canCreate,
        "canThumbnail" to canThumbnail,
    )
}

/** Query the [DocumentFile] for the flags
 *
 * @param context The context of the application
 * @return `true` if the [DocumentFile] has the given flag, otherwise `false`
 */
fun DocumentFile.hasFlag(context: Context, flag: Int): Boolean {
    return flags(context) and flag != 0
}

/** Get [DocumentFile] flags
 *
 * @param context The context of the application
 * @return The flags of the [DocumentFile]
 */
fun DocumentFile.flags(context: Context): Int = context.contentResolver.query(
    uri,
    arrayOf(DocumentsContract.Document.COLUMN_FLAGS),
    null,
    null,
    null
)?.use { cursor ->
    if (cursor.moveToFirst()) {
        cursor.getInt(0)
    } else 0
} ?: 0

/** Check if the [DocumentFile] is writable
 *
 * @param context The context of the application
 * @return `true` if the [DocumentFile] has proper writable permissions, otherwise `false`
 */
fun DocumentFile.isWritable(context: Context): Boolean {
    //TODO check maybe switch to persistedUri
    return (context.checkCallingOrSelfUriPermission(uri, Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            == PackageManager.PERMISSION_GRANTED)
}

/** Check if the [DocumentFile] can be deleted - FLAG_SUPPORTS_DELETE*/
fun DocumentFile.canDelete(context: Context): Boolean =
    hasFlag(context, DocumentsContract.Document.FLAG_SUPPORTS_DELETE)

/** Check if the `DocumentFile` can be renamed - has flag FLAG_SUPPORTS_RENAME */
//fun DocumentFile.canRename(context: Context): Boolean =
//    hasFlag(context, DocumentsContract.Document.FLAG_SUPPORTS_RENAME)

/** Check if the [DocumentFile] is directory and can create documents
 * has flag FLAG_DIR_SUPPORTS_CREATE
 */
fun DocumentFile.canCreate(context: Context): Boolean =
    isDirectory && hasFlag(context, DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE)

///** Check if the [DocumentFile] can have a thumbnail
// * has flag FLAG_SUPPORTS_THUMBNAIL
// */
//fun DocumentFile.canThumbnail(context: Context): Boolean =
//    hasFlag(context, DocumentsContract.Document.FLAG_SUPPORTS_THUMBNAIL)


/** Check if the [DocumentFile] can have an alternate thumbnail
 *
 * Used as alternative due to common providers only provide thumbnails for images.
 * @return `true` if the [DocumentFile] can have an alternate thumbnail, otherwise `false`
 */
//TODO: add additional thumbnail types like docx, xls, maybe others
fun DocumentFile.canThumbnailAlternate(context: Context): Boolean =
    canRead() && (type == "application/pdf" || isVideo(context) || isImage(context))

/** Get the persisted URI of the [DocumentFile]
 *
 * `ACTION_OPEN_DOCUMENT_TREE` - returns real treeUri, to which grants persisted permissions.
 * But when instantiating a [DocumentFile] from the treeUri, it returns a different URI,
 * and when doing matching, it fails.
 *
 * @return The persisted URI of the [DocumentFile]
 */
fun DocumentFile.persistedUri(context: Context): Uri = when {

    ///Due to DocumentFile for Directory, has another URI
    isDirectory -> DocumentsContract.buildTreeDocumentUri(
        uri.authority,
        uri.getDocumentId(context)
    )
    ///Due to DocumentFile for File, has another URI, we check if it is a file, get content URI
    else -> activityUri(context)
}

/** Get the persisted permissions of the [DocumentFile]
 *
 * @return [UriPermission] The persisted permissions of the [DocumentFile]
 */
fun DocumentFile.persistedPermissions(context: Context): UriPermission? {
    return context.contentResolver.persistedUriPermissions.find { it.uri == persistedUri(context) }
}

/** This is used to list all the files and directories in a [DocumentFile] if it is a directory
 *
 * @param context The context of the application
 * @param filterType The list of mime types to filter.
 * @param filterName String to filter by name (if contains)
 * If this is not null or empty, only documents that match one of the given MIME types are shown.
 * @return A list of [DocumentFile.toMapResult] results for each file or directory in list
 */
fun DocumentFile.listDocuments(
    context: Context,
    filterType: List<String> = emptyList(),
    filterName: String? = null
): List<Map<String, Any?>> =
    when {
        isDirectory -> listFiles().mapNotNull {
            if (it.isMimeTypeAllowed(filterType) && it.nameContains(filterName ?: "")) {
                it.toMapResult(context)
            } else {
                null
            }
        }

        else -> emptyList()
    }


/** This extension is used to get the activity URI of the [DocumentFile]
 * If the URI scheme is `file`, then it is converted to a `content` URI
 * using the `FileProvider`
 */
fun DocumentFile.activityUri(context: Context): Uri = when {
    uri.scheme == "file" -> uri.toFileProviderUri(context)
    else -> uri
}

/** Determine if the [DocumentFile] is an app file
 *
 * Checks if the URI contains the package name of the application
 *
 * @return `true` if the [DocumentFile] is an app file, otherwise `false`
 */
fun DocumentFile.isAppFile(context: Context): Boolean =
    uri.toString().contains(context.packageName)

/** Determine if the [DocumentFile] is an app directory
 *
 * Checks if the URI contains the package name of the application
 *
 * @return `true` if the [DocumentFile] is an app directory, otherwise `false`
 */
fun DocumentFile.isAppDir(context: Context): Boolean =
    isDirectory && uri.toString().contains(context.packageName)

/** This extension is used to check if the [DocumentFile] mimeType is allowed
 *
 * @param filter The list of mime types to filter.
 * If this is not null or empty, only documents that match one of the given MIME types are shown.
 * If the filter contains `directory`, then directories are allowed.
 * @return `true` if the [DocumentFile] mimeType is allowed, otherwise `false`
 */
fun DocumentFile.isMimeTypeAllowed(filter: List<String>): Boolean {
    if (filter.isEmpty() || (isDirectory && filter.contains("directory"))) return true

    return filter.any {
        it == type || it.split("/").let { parts ->
            parts.size > 1 &&
                    (parts[1].trim() == "*" || parts[1].trim().isEmpty()) &&
                    type?.startsWith(parts[0]) == true
        }
    }
}

/** This extension is used to get the file extension of the [DocumentFile]
 *
 * @param context The context of the application
 * @return The file extension of the [DocumentFile]
 */
fun DocumentFile.getFileExtension(context: Context): String {
    val mimeType = context.contentResolver.getType(uri) ?: return ""
    return MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
        ?: name?.substringAfterLast('.', "") ?: ""
}

/** Check if the [DocumentFile] name contains a string
 *
 * @param str The string to check if it is contained in the name
 * @return `true` if the [DocumentFile] name contains the string, otherwise `false`
 * Returns `true` if `name` is `null`
 */
fun DocumentFile.nameContains(str: String): Boolean =
    name?.contains(str, ignoreCase = true) ?: str.isEmpty()

/** Get the name of the [DocumentFile] as a file name
 *
 * @return The name of the [DocumentFile] as a file name,
 * replacing invalid characters with underscores */
fun DocumentFile.nameAsFileName(): String? = name?.asFileName()

/** Get the base name of the [DocumentFile]
 *
 * @param isMedia If the [DocumentFile] is a media file
 * @return First, try to get the name of the [DocumentFile] as a file name, if it is not null.
 * If the [DocumentFile] is a media file, the base name will be `docman_media_{timestamp}`,
 * otherwise the base name will be `docman_file_{timestamp}`
 */
fun DocumentFile.getBaseName(isMedia: Boolean = false): String =
    nameAsFileName()?.substringBeforeLast('.')
        ?: ((if (isMedia) "docman_media" else "docman_file") + "_${System.currentTimeMillis()}")

/** Check if the [DocumentFile] type is an image
 *
 * It checks if the `type` of the [DocumentFile] starts with `image/`,
 * otherwise it checks if the URI is an image
 * @param context The context of the application
 */
fun DocumentFile.isImage(context: Context): Boolean =
    type?.startsWith("image/") ?: uri.isImage(context)

/** Check if the [DocumentFile] type is a video
 *
 * It checks if the `type` of the [DocumentFile] starts with `video/`,
 * otherwise it checks if the URI is a video
 * @param context The context of the application
 */
fun DocumentFile.isVideo(context: Context): Boolean =
    type?.startsWith("video/") ?: uri.isVideo(context)

/** Check if the [DocumentFile] is a visual media
 *
 * It checks if the [DocumentFile] is an image or a video
 * @param context The context of the application
 */
fun DocumentFile.isVisualMedia(context: Context): Boolean =
    isImage(context) || isVideo(context)

/** Copy the [DocumentFile] to the cache directory.
 *
 *  Must be called from a coroutine.
 *
 * @param context The context of the application
 * @param quality The quality of the image if the [DocumentFile] is an image
 * @return The path of the copied file in the cache directory,
 * first it tries to save the file to the external cache directory, if it fails,
 * it tries to save the file to the internal cache directory.
 *
 * @see DocManFiles.documentFileToCache
 */
suspend fun DocumentFile.copyToCache(
    context: Context,
    quality: Int = 100
): String = DocManFiles.documentFileToCache(this, context, quality)

/** Save the [DocumentFile] to a URI.
 *
 *  Must be called from a coroutine.
 *
 * @param to The URI to save the [DocumentFile] to.
 * Commonly uri is obtained from `Intent.ACTION_CREATE_DOCUMENT`, but not limited to it.
 * @param deleteSource If `true`, the source [DocumentFile] will be deleted after saving.
 * This also depends if the source [DocumentFile] can be deleted via [canDelete]
 * @param context The context of the application
 * @return The saved [DocumentFile] or `null` if the save operation fails
 *
 * @see DocManFiles.documentFileSaveToUri
 */
suspend fun DocumentFile.saveToUri(
    to: Uri,
    deleteSource: Boolean = false,
    context: Context,
): DocumentFile? = DocManFiles.documentFileSaveToUri(this, to, deleteSource, context)

/** Write content to the [DocumentFile].
 *
 *  Must be called from a coroutine.
 *
 * @param content The content to write to the [DocumentFile]
 * @param context The context of the application
 *
 * @see DocManFiles.writeContentToDocumentFile
 */
suspend fun DocumentFile.writeContent(
    content: ByteArray,
    context: Context
) = DocManFiles.writeContentToDocumentFile(this, content, context)

/** Copy the file [DocumentFile] to directory [DocumentFile].
 *
 *  Must be called from a coroutine.
 *
 * @param dir The directory to copy the [DocumentFile] to.
 * Must have `canWrite` permission.
 * @param name The custom name of the copied [DocumentFile], default is [getBaseName] value.
 * @param context The context of the application
 * @return The copied [DocumentFile] or `null` if the copy operation fails
 * @throws UnsupportedOperationException if [dir] is not a tree directory
 * @throws FileNotFoundException if there is a problem with input/output streams
 * @see DocManFiles.copyDocumentFile
 */
suspend fun DocumentFile.copyTo(
    dir: DocumentFile,
    name: String?,
    context: Context
): DocumentFile? = DocManFiles.copyDocumentFile(this, dir, name, context)

/** Move the file [DocumentFile] to directory [DocumentFile].
 *
 *  Must be called from a coroutine.
 *
 * @param dir The directory to move the [DocumentFile] to.
 * Must have `canWrite` permission.
 * @param name The new name of the [DocumentFile], default is the result of [getBaseName].
 * @param context The context of the application
 * @return The moved [DocumentFile] or `null` if the move operation fails
 * @throws UnsupportedOperationException if [dir] is not a tree directory
 * @throws FileNotFoundException if there is a problem with input/output streams
 * @see DocManFiles.moveDocumentFile
 */
suspend fun DocumentFile.moveTo(
    dir: DocumentFile,
    name: String?,
    context: Context
): DocumentFile? = DocManFiles.moveDocumentFile(this, dir, name, context)

//fun DocumentFile.readContent(context: Context): ByteArray? =
//    DocManFiles.readDocumentFile(this, context)


/** Delete the [DocumentFile].
 *
 *  Must be called from a coroutine.
 *
 * @param context The context of the application
 * @return `true` if the [DocumentFile] is deleted, otherwise `false`
 *
 * @see DocManFiles.deleteDocument
 */
suspend fun DocumentFile.deleteDocument(context: Context): Boolean =
    DocManFiles.deleteDocument(this, context)

/** Get the thumbnail of the [DocumentFile].
 *
 * Must be called from a coroutine.
 *
 * @param size The size of the thumbnail
 * @param quality The quality of the thumbnail
 * @param format The format of the thumbnail image.
 *
 * @return The [DocumentThumbnail] of the [DocumentFile]
 * or `null` if the thumbnail cannot be generated.
 */
suspend fun DocumentFile.getThumbnail(
    size: Size,
    quality: Int = 100,
    format: BitmapCompressFormat,
    context: Context
): DocumentThumbnail? =
    DocManMedia.getThumbnail(this, size, quality, format, context)

/** Get the thumbnail file of the [DocumentFile].
 *
 * Must be called from a coroutine.
 * Same as [getThumbnail] but saves the thumbnail to a file in the cache directory.
 *
 * @return The path of the thumbnail file in the cache directory.
 * @see getThumbnail
 */
suspend fun DocumentFile.getThumbnailFile(
    size: Size,
    quality: Int = 100,
    format: BitmapCompressFormat,
    context: Context
): String? =
    DocManFiles.getThumbnailFile(this, size, quality, format, context)

