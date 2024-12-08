package devdf.plugins.docman.extensions

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import androidx.core.content.FileProvider
import androidx.core.net.toFile
import androidx.documentfile.provider.DocumentFile
import devdf.plugins.docman.utils.DocManBuild
import devdf.plugins.docman.utils.DocManMimeType


/** Verify if it is a tree URi */
fun Uri.isTreeUri(): Boolean {
    if (DocManBuild.isTreeUri()) return DocumentsContract.isTreeUri(this)

    val paths = pathSegments

    return paths.size >= 2 && "tree" == paths[0]
}

/** Verify if it is a document URi
 * DocumentsContract.isDocumentUri(context, this)
 * */
fun Uri.isDocumentUri(context: Context): Boolean = DocumentsContract.isDocumentUri(context, this)

/** Convert URI to FileProvider URI */
fun Uri.toFileProviderUri(context: Context): Uri = FileProvider.getUriForFile(
    context,
    context.packageName + ".docman.files", //applicationContext.packageName
    toFile()
)

/** Convert [Uri] to [DocumentFile] */
fun Uri.toDocumentFile(context: Context): DocumentFile? {

    val doc: DocumentFile? = when {
        isTreeUri() -> DocumentFile.fromTreeUri(context, this)
        // If uri is file, convert it to DocumentFile,
        // If uri is local directory, but not exists, create it
        scheme == "file" -> runCatching {
            // if uri is file then mkdirs will throw exception
            val file = toFile().apply { if (!exists() && !mkdirs()) return null }
            DocumentFile.fromFile(file)
        }.getOrNull()
        //Also handle media uris: [content://media/external/file/106] only after activity result
        //Such uris can only be saved to cache after picking activity
        else -> runCatching { DocumentFile.fromSingleUri(context, this) }.getOrNull()
    }

    return when {
        doc?.exists() == true && (doc.isDirectory || doc.isFile) -> doc
        else -> null
    }
}

fun Uri.getDocumentId(context: Context): String {
    var documentId = DocumentsContract.getTreeDocumentId(this)
    if (DocumentsContract.isDocumentUri(context, this)) {
        documentId = DocumentsContract.getDocumentId(this)
    }
    return documentId
}

/** Convert [Uri] to [DocumentFile] -> [DocumentFile.toMapResult]  */
fun Uri.toDocumentMap(context: Context): Map<String, Any?>? =
    toDocumentFile(context)?.toMapResult(context)

/** Convert [Uri] to [DocumentFile] -> Save DocumentFile to cache -> Returns path of cache file  */
suspend fun Uri.toDocumentCache(context: Context): String? =
    toDocumentFile(context)?.copyToCache(context)

/** Check if [Uri] is uri of image mime type  */
fun Uri.isImage(context: Context): Boolean = DocManMimeType.isImage(context, this)

/** Check if [Uri] is uri of video mime type  */
fun Uri.isVideo(context: Context): Boolean = DocManMimeType.isVideo(context, this)

/** Check if [Uri] is uri of [mimeType]  */
fun Uri.isMediaMimeType(mimeType: String, context: Context): Boolean {
    val type = DocManMimeType.determineMediaType(context, this)
    return type != null && type == mimeType
}