package devdf.plugins.docman.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Point
import android.net.Uri
import android.util.Log
import android.util.Size
import androidx.core.net.toFile
import androidx.core.net.toUri
import androidx.documentfile.provider.DocumentFile
import devdf.plugins.docman.extensions.activityUri
import devdf.plugins.docman.extensions.canDelete
import devdf.plugins.docman.extensions.getBaseName
import devdf.plugins.docman.extensions.getFileExtension
import devdf.plugins.docman.extensions.isAppFile
import devdf.plugins.docman.extensions.isImage
import devdf.plugins.docman.extensions.isMediaMimeType
import devdf.plugins.docman.extensions.isPDF
import devdf.plugins.docman.extensions.isVideo
import devdf.plugins.docman.extensions.isVisualMedia
import devdf.plugins.docman.extensions.nameAsFileName
import devdf.plugins.docman.extensions.toDocumentFile
import io.flutter.util.PathUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.io.InputStreamReader
import java.nio.charset.Charset


/** Helper class for file operations */
class DocManFiles {
    companion object {

        /** Convert JSON string to map
         * Used for parse provider.json file
         *
         * @param json The JSON string to convert
         * @return The converted map
         */
        fun jsonToMap(json: String): Map<String, Any?> {
            val map = mutableMapOf<String, Any?>()
            val jsonMap = JSONObject(json)
            jsonMap.keys().forEach {
                map[it] = jsonMap[it]
                //1. Check for array and convert to list
                if (jsonMap[it] is JSONArray) {
                    val list = mutableListOf<Any?>()
                    for (i in 0 until (jsonMap[it] as JSONArray).length()) {
                        list.add((jsonMap[it] as JSONArray).get(i))
                    }
                    map[it] = list
                }
                //2. Check for nested JSON object and convert to map
                if (jsonMap[it] is JSONObject) {
                    map[it] = jsonToMap(jsonMap[it].toString())
                }

            }
            return map
        }

        /** Save [DocumentFile] to a cache file.
         *
         * @param doc The [DocumentFile] to save
         * @param context The context of the application
         * @param quality The quality of the image
         * if the document is an image, is used for compression.
         *
         * If [DocumentFile] is visual media, it is saved to [cacheMediaDir],
         * otherwise it is saved to [cacheFilesDir].
         * If the file already exists, overwrite it.
         *
         * @return The path of the saved file in the cache directory.
         */
        suspend fun documentFileToCache(
            doc: DocumentFile,
            context: Context,
            quality: Int
        ): String = withContext(Dispatchers.IO) {
            //1. Set proper target directory
            val targetDirectory = if (doc.isVisualMedia(context))
                cacheMediaDir(context) else cacheFilesDir(context)
            //2. Set proper target file name
            val targetFileName = doc.nameAsFileName()
                ?: "${doc.getBaseName(doc.isVisualMedia(context))}.${
                    doc.getFileExtension(context)
                }"
            //3. Create target file, delete if it exists
            val targetFile = File(targetDirectory, targetFileName).apply {
                if (fileExists(toUri(), context)) delete()
            }
            //4. Write the file
            if (doc.isImage(context)) {
                writeFromImageUriToFile(doc.uri, targetFile, context, quality)
            } else {
                writeFromFileUriToFile(doc.uri, targetFile, context)
            }

            targetFile.path
        }

        /** Write content to a [DocumentFile] */
        suspend fun writeContentToDocumentFile(
            doc: DocumentFile,
            content: ByteArray,
            context: Context
        ) = withContext(Dispatchers.IO) { writeContentToUri(content, doc.uri, context) }

        /** Save a [DocumentFile] to a given URI, delete source if needed (possible) */
        suspend fun documentFileSaveToUri(
            doc: DocumentFile,
            uri: Uri,
            deleteSource: Boolean = false,
            context: Context,
        ): DocumentFile? = withContext(Dispatchers.IO) {
            context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                context.contentResolver.openInputStream(doc.activityUri(context))
                    ?.use { inputStream -> inputStream.copyTo(outputStream) }
            }

            if (deleteSource) deleteDocument(doc, context)
            uri.toDocumentFile(context)
        }

        /** Delete a [DocumentFile] recursively */
        suspend fun deleteDocument(doc: DocumentFile, context: Context): Boolean =
            withContext(Dispatchers.IO) { deleteDocumentRecursive(doc, context) }

        /** Read the content of the DocumentFile [Uri] as a string stream */
        suspend fun streamUriAsString(
            uri: Uri,
            buffer: Int,
            start: Int,
            charset: String,
            context: Context,
            onSuccess: suspend (String) -> Unit,
        ) = context.contentResolver.openInputStream(uri)?.use { inputStream ->
            //1. Skip the start bytes
            inputStream.skip(start.toLong())
            //2. Set buffer size
            val bufferSize = CharArray(buffer)
            //3. Initialize reader
            val reader = InputStreamReader(inputStream, Charset.forName(charset))
            //4. Initialize read variable
            var read: Int
            //5. Read the stream in chunks with null check for eventSink
            while (reader.read(bufferSize).also { read = it } > 0) {
                onSuccess(String(bufferSize, 0, read))
            }
        } ?: throw IOException("Unable to open input stream for URI: $uri")

        /** Read the content of the DocumentFile [Uri] as a [ByteArray] */
        suspend fun streamUriAsBytes(
            uri: Uri,
            buffer: Int,
            start: Int,
            context: Context,
            onSuccess: suspend (ByteArray) -> Unit,
        ) = context.contentResolver.openInputStream(uri)?.use { inputStream ->
            //1. Skip the start bytes
            inputStream.skip(start.toLong())
            //2. Set buffer size
            val bufferSize = ByteArray(buffer)
            //3. Initialize read variable
            var read: Int
            //4. Read the stream in chunks with null check for eventSink
            while (inputStream.read(bufferSize).also { read = it } > 0) {
                onSuccess(bufferSize.copyOfRange(0, read))
            }
        } ?: throw IOException("Unable to open input stream for URI: $uri")

        /** Read the content of the [DocumentFile] as a byte array */
        fun readDocumentFile(doc: DocumentFile, context: Context): ByteArray? = try {
            context.contentResolver.openInputStream(doc.uri)?.use { it.readBytes() }
        } catch (_: Exception) {
            null
        }

        /** Copy a [DocumentFile] to a target directory */
        suspend fun copyDocumentFile(
            doc: DocumentFile,
            targetDir: DocumentFile,
            name: String?,
            context: Context
        ): DocumentFile? = withContext(Dispatchers.IO) {
            //1. Create the target file
            var targetDoc: DocumentFile? = null
            //2. Copy the file
            runCatching {
                targetDoc = targetDir.createFile(doc.type!!, name ?: doc.getBaseName())?.apply {
                    context.contentResolver.openInputStream(doc.uri)?.use { inputStream ->
                        context.contentResolver.openOutputStream(this.uri)?.use { outputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }
                }
                targetDoc
                //3. Delete the target file if copy failed
            }.getOrElse { e -> targetDoc?.delete().let { throw e } }
        }

        /** Move a [DocumentFile] to a target directory */
        suspend fun moveDocumentFile(
            doc: DocumentFile,
            targetDir: DocumentFile,
            name: String?,
            context: Context
        ): DocumentFile? = withContext(Dispatchers.IO) {
            copyDocumentFile(doc, targetDir, name, context)?.takeIf {
                deleteDocument(doc, context) || it.delete().let { false }
            }
        }

        /** Get thumbnail file for a [DocumentFile] */
        suspend fun getThumbnailFile(
            doc: DocumentFile,
            size: Size,
            quality: Int,
            format: BitmapCompressFormat,
            context: Context
        ): String? = withContext(Dispatchers.IO) {
            //1. Prepare target file
            val targetFileName = "thumb_${doc.getBaseName(true)}.${format.extension}"
            val targetFile = File(thumbnailsCacheDir(context), targetFileName)
            //2. Get thumbnail bitmap and compress it to the target file
            try {
                DocManMedia.getThumbnailBitmap(doc, size, context)?.let { bitmap ->
                    if (fileExists(targetFile.toUri(), context)) targetFile.delete()
                    targetFile.outputStream().use { outputStream ->
                        DocManMedia.compressBitmap(bitmap, quality, format).writeTo(outputStream)
                        bitmap.recycle()
                    }
                    targetFile.path
                }
            } catch (_: Exception) {
                null
            }
        }

        /** Get Thumbnail as file for [File] */
        fun getThumbnailForFile(
            file: File,
            thumb: File,
            size: Point,
            context: Context
        ) = runCatching {
            val doc = DocumentFile.fromFile(file)
            val thumbSize = Size(size.x, size.y)

            when {
                doc.isVideo(context) -> DocManMedia.videoThumbnail(doc, thumbSize, context)
                doc.isPDF() -> DocManMedia.pdfThumbnail(
                    doc,
                    thumbSize,
                    context
                )

                else -> null
            }?.let {
                //2. If bitmap is not null, save it to cache
                thumb.outputStream().use { stream ->
                    it.compress(Bitmap.CompressFormat.JPEG, 90, stream)
                }
            }

        }.getOrNull()

        /** Generate a file name for temporary files */
        fun genFileName(): String = "docman_file_${System.currentTimeMillis() % 100000}"

        /** Clear all cache directories used by plugin */
        fun clearCacheDirectories(context: Context) {
            listOfNotNull(
                context.externalCacheDir?.let { File(it, "docManMedia") },
                context.externalCacheDir?.let { File(it, "docMan") },
                File(context.cacheDir, "docManMedia"),
                File(context.cacheDir, "docMan")
            ).forEach { dir ->
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        dir.deleteRecursively()
                    } catch (e: Exception) {
                        Log.e("DocManFiles", "Failed to delete directory: ${dir.path}", e)
                    }
                }
            }
        }

        /** Get provider directory.
         * If external files directory is not available, internal data directory is used.
         *
         * @param rootPath The relative path of the root provider directory
         * @param context The context of the application
         * @return The provider directory
         */
        fun providerDir(rootPath: String, context: Context): File {
            val dir = context.getExternalFilesDir(null) ?: File(PathUtils.getDataDirectory(context))
            return dir.resolve(rootPath).apply { if (!exists()) mkdir() }
        }

        /** Get plugin cache directory for thumbnails */
        fun thumbnailsCacheDir(context: Context): File {
            return cacheMediaDir(context).resolve("thumbs").apply {
                if (!exists()) mkdir()
                deleteOnExit()
            }
        }

        /** Get plugin cache directory for media files */
        private fun cacheMediaDir(context: Context): File =
            createCacheTempDir(context, "docManMedia")

        /** Get plugin cache directory for files */
        private fun cacheFilesDir(context: Context): File = createCacheTempDir(context, "docMan")

        /** Create temporary cache directory with a given name.
         * First, external cache directory is checked,
         * if it does not exist, internal cache directory is used.
         * Directory is created if it does not exist and is marked for deletion on application exit.
         */
        private fun createCacheTempDir(context: Context, name: String): File {
            return File(context.externalCacheDir ?: context.cacheDir, name).apply {
                if (!exists()) mkdir()
                // Method not working properly on Android, so we leave it as is.
                // But deleting all created folders on application start
                // or through [clearCacheDirectories] method
                deleteOnExit()
            }
        }

        /** Write from a file [Uri] to a [File] */
        private fun writeFromFileUriToFile(from: Uri, to: File, context: Context) {
            context.contentResolver.openInputStream(from)?.use { inputStream ->
                to.outputStream().use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            } ?: throw IOException("Unable to open input stream for URI: $from")
        }

        /** Write content as [ByteArray] to a [Uri] */
        private fun writeContentToUri(content: ByteArray, to: Uri, context: Context) {
            context.contentResolver.openOutputStream(to)?.use { outputStream ->
                outputStream.write(content)
            } ?: throw IOException("Unable to open output stream for URI: $to")

        }

        /** Write from an image [Uri] to a [File]
         * this is separate function to handle image compression
         * */
        private fun writeFromImageUriToFile(
            from: Uri,
            to: File,
            context: Context,
            quality: Int = 100
        ) {
            context.contentResolver.openInputStream(from)?.use { inputStream ->
                to.outputStream().use { outputStream ->
                    val originalBitmap = BitmapFactory.decodeStream(inputStream)
                    val compressedStream = DocManMedia.compressBitmap(
                        originalBitmap,
                        quality,
                        format = when {
                            from.isMediaMimeType("image/webp", context) -> BitmapCompressFormat.WEBP
                            from.isMediaMimeType("image/png", context) -> BitmapCompressFormat.PNG
                            else -> null
                        }
                    )
                    //Recycle the original bitmap
                    originalBitmap.recycle()
                    compressedStream.writeTo(outputStream)
                }
            } ?: throw IOException("Unable to open input stream for URI: $from")
        }


        /** Delete a [DocumentFile] recursively */
        private fun deleteDocumentRecursive(doc: DocumentFile, context: Context): Boolean {
            return try {
                //1. Check if document is a directory
                if (doc.isDirectory) {
                    doc.listFiles().forEach { deleteDocumentRecursive(it, context) }
                }
                //2. Check if document is initialized as file
                if (doc.isAppFile(context)) {
                    doc.uri.toFile().delete()
                } else {
                    //3. Delete the document if it can be deleted
                    doc.canDelete(context) && doc.delete()
                }
            } catch (_: Exception) {
                false
            }
        }

        /** Check if file via uri exists, if exception is thrown,
         * file does not exist or we don't have permission, otherwise true */
        private fun fileExists(uri: Uri, context: Context): Boolean = try {
            context.contentResolver.openFileDescriptor(uri, "r")?.close()
            true
        } catch (_: Exception) {
            false
        }
    }

}