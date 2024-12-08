package devdf.plugins.docman.utils

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import android.webkit.MimeTypeMap

class DocManMimeType {
    companion object {
        fun combine(mimeTypes: List<String>?, extensions: List<String>?): List<String> {
            val mimeTypesSet = mutableSetOf<String>()
            //1. Filter current mimeTypes & add to the set
            mimeTypes?.forEach {
                //1.1 Check if second part of mimeType is *
                if (it.endsWith("/*")) mimeTypesSet.add(it)
                //1.2 Check if prefix mime is already in set with asterisks
                if (!mimeTypesSet.contains("${it.split("/")[0]}/*")) {
                    if (MimeTypeMap.getSingleton().hasMimeType(it) || it == "directory") {
                        mimeTypesSet.add(it)
                    }
                }
            }
            //2. Filter extensions and add to the set
            extensions?.forEach {
                MimeTypeMap.getSingleton().getMimeTypeFromExtension(it)?.let { mimeType ->
                    mimeTypesSet.add(mimeType)
                }
            }

            return mimeTypesSet.toList()
        }

        fun fromExtension(extension: String): String? =
            MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)

        fun isImage(context: Context, uri: Uri): Boolean {
            return determineMediaType(context, uri)?.let {
                return it.startsWith("image/")
            } ?: false
        }

        fun isVideo(context: Context, uri: Uri): Boolean {
            return determineMediaType(context, uri)?.let {
                return it.startsWith("video/")
            } ?: false
        }


        fun determineMediaType(context: Context, uri: Uri): String? {
            //1. Try to get MIME type from content resolver
            return context.contentResolver.getType(uri)
                ?: fromMediaStoreFilesQuery(context, uri)
                ?: fromMediaMetaData(context, uri)
        }

        private fun fromMediaStoreFilesQuery(context: Context, uri: Uri): String? {
            return try {
                val column = MediaStore.Files.FileColumns.MIME_TYPE
                context.contentResolver.query(
                    uri,
                    arrayOf(column),
                    null,
                    null,
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        cursor.getString(cursor.getColumnIndexOrThrow(column))
                    } else null
                }
            } catch (e: Exception) {
                null
            }
        }

        private fun fromMediaMetaData(context: Context, uri: Uri): String? {
            val retriever = MediaMetadataRetriever()
            return try {
                retriever.setDataSource(context, uri)
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)
            } catch (e: Exception) {
                null
            } finally {
                retriever.release()
            }
        }
    }
}