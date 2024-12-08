package devdf.plugins.docman.utils

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ImageDecoder
import android.graphics.Point
import android.graphics.pdf.PdfRenderer
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.OPTION_PREVIOUS_SYNC
import android.provider.DocumentsContract
import android.util.Size
import androidx.documentfile.provider.DocumentFile
import devdf.plugins.docman.extensions.canThumbnailAlternate
import devdf.plugins.docman.extensions.isImage
import devdf.plugins.docman.extensions.isVideo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import kotlin.math.min

/** DocumentThumbnail - used to store thumbnail data */
data class DocumentThumbnail(val bytes: ByteArray, val width: Int, val height: Int) {
    fun toMap(): Map<String, Any> = mapOf(
        "bytes" to bytes,
        "width" to width,
        "height" to height
    )
}

/** Bitmap Compression Format - commonly used during thumbnail generation process */
enum class BitmapCompressFormat {
    JPEG, PNG, WEBP;

    val extension: String
        get() = when (this) {
            JPEG -> "jpg"
            PNG -> "png"
            WEBP -> "webp"
        }
}


class DocManMedia {
    companion object {
        /** Get [DocumentThumbnail] for [DocumentFile] */
        suspend fun getThumbnail(
            doc: DocumentFile,
            size: Size,
            quality: Int,
            format: BitmapCompressFormat,
            context: Context
        ): DocumentThumbnail? = withContext(Dispatchers.IO) {
            //1. Get the Bitmap
            //2. Return the DocumentThumbnail
            getThumbnailBitmap(doc, size, context)?.let {
                val docThumb = DocumentThumbnail(
                    bytes = compressBitmap(it, quality, format).toByteArray(),
                    width = it.width,
                    height = it.height
                )
                it.recycle()
                docThumb
            }
        }

        /** Get thumbnail Bitmap for [DocumentFile] by any possible means */
        fun getThumbnailBitmap(
            doc: DocumentFile,
            size: Size,
            context: Context,
        ): Bitmap? = runCatching {
            //1. Check if we can get thumbnail from the document fastest way
            DocumentsContract.getDocumentThumbnail(
                context.contentResolver,
                doc.uri,
                Point(size.width, size.height),
                null
            )
        }.getOrNull() ?: runCatching {
            //2. If not, try to load thumbnail from content resolver if allowed
            if (DocManBuild.loadThumbnail()) {
                context.contentResolver.loadThumbnail(doc.uri, size, null)
            } else null
        }.getOrNull() ?: if (doc.canThumbnailAlternate(context)) {
            //3. If not, try to get thumbnail by alternate means
            when {
                doc.isImage(context) -> imageThumbnail(doc, size, context)
                doc.isVideo(context) -> videoThumbnail(doc, size, context)
                doc.type == "application/pdf" -> pdfThumbnail(doc, size, context)
                else -> null
            }
        } else null

        /** Compress Bitmap to a ByteArrayOutputStream */
        fun compressBitmap(
            bitmap: Bitmap,
            imageQuality: Int,
            format: BitmapCompressFormat? = null,
        ): ByteArrayOutputStream {
            val outputStream = ByteArrayOutputStream()
            val (compressType, quality) = compressionAndQuality(format, imageQuality)

            bitmap.compress(compressType, quality, outputStream)

            return outputStream
        }


        /** Try to get image thumbnail */
        private fun imageThumbnail(
            doc: DocumentFile,
            size: Size,
            context: Context
        ): Bitmap? = runCatching {
            //1. Use ImageDecoder for newer versions if possible
            if (DocManBuild.canUseImageDecoder()) {
                ImageDecoder.decodeBitmap(
                    ImageDecoder.createSource(context.contentResolver, doc.uri)
                ) { decoder, info, _ ->
                    // sample down if needed.
                    val sample = getSampleRatio(info.size, size)
                    if (sample > 1) {
                        decoder.setTargetSampleSize(sample)
                    }
                }
            } else null
        }.getOrNull() ?: runCatching {
            //2. Fallback to BitmapFactory for older versions, only jpg, png, webp supported
            context.contentResolver.openInputStream(doc.uri)?.use { inputStream ->
                BitmapFactory.decodeStream(inputStream)
            }?.let { getScaledBitmap(it, size) }
        }.getOrNull()

        /** Try to get video thumbnail */
        private fun videoThumbnail(
            doc: DocumentFile,
            size: Size,
            context: Context
        ): Bitmap? = runCatching {
            //1. Set up media retriever & frame
            val retriever = MediaMetadataRetriever()
            var frame: Bitmap? = null
            //2. Set data source
            retriever.setDataSource(context, doc.uri)
            //3. Get scaled embedded thumbnail if available
            retriever.embeddedPicture?.let { frame = getScaledBitMapFromByteArray(it, size) }
            //4. Once again, set frame if no embedded thumbnail
            if (frame == null) {
                //4.1. Calculate sampleSize
                val width =
                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                        ?.toInt() ?: size.width
                val height =
                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                        ?.toInt() ?: size.height
                val sampleSize = getSampleSize(Size(width, height), size)

                frame = when {
                    //4.2 For newer versions, use getScaledFrameAtTime
                    DocManBuild.getScaledFrameAtTime() -> retriever.getScaledFrameAtTime(
                        -1, OPTION_PREVIOUS_SYNC,
                        sampleSize.width, sampleSize.height
                    )
                    //4.3 For older versions, use frameAtTime
                    else -> retriever.frameAtTime?.let { getScaledBitmap(it, size) }
                }
            }
            //5. Close retriever
            retriever.close()
            frame
        }.getOrNull()

        /** Try to get pdf thumbnail */
        private fun pdfThumbnail(
            doc: DocumentFile,
            size: Size,
            context: Context
        ): Bitmap? = runCatching {
            //1. Setting up the renderer
            context.contentResolver.openFileDescriptor(doc.uri, "r")?.use { fileDescriptor ->
                //2. Get the first page
                val page = PdfRenderer(fileDescriptor).openPage(0)
                //3. Get the bitmap from the page
                val bitmap =
                    Bitmap.createBitmap(page.width, page.height, Bitmap.Config.ARGB_8888)
                //4. Draw white background for the bitmap
                val canvas = Canvas(bitmap)
                canvas.drawColor(Color.WHITE)
                page.render(
                    bitmap,
                    null,
                    null,
                    PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY
                )
                page.close()
                //5. Scale it if needed
                getScaledBitmap(bitmap, size)
            }
        }.getOrNull()


        /** Get Proper Compression format & Quality for the Image */
        @SuppressLint("NewApi")
        private fun compressionAndQuality(
            format: BitmapCompressFormat?,
            quality: Int
        ): Pair<Bitmap.CompressFormat, Int> = when (format) {
            BitmapCompressFormat.WEBP -> {
                if (DocManBuild.newCompressFormatWEBP()) {
                    Pair(Bitmap.CompressFormat.WEBP_LOSSLESS, 100 - quality)
                } else {
                    Pair(Bitmap.CompressFormat.WEBP, quality)
                }
            }

            BitmapCompressFormat.PNG -> Pair(Bitmap.CompressFormat.PNG, 100)
            else -> Pair(Bitmap.CompressFormat.JPEG, quality)
        }


        /** Get Bitmap from ByteArray scaled to the size if needed */
        private fun getScaledBitMapFromByteArray(byteArray: ByteArray, size: Size): Bitmap =
            getScaledBitmap(
                BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size),
                size
            )

        private fun getScaledBitmap(bitmap: Bitmap, size: Size): Bitmap {
            val scaleSize = getSampleSize(Size(bitmap.width, bitmap.height), size)
            return Bitmap.createScaledBitmap(
                bitmap,
                scaleSize.width, //(bitmap.width * ratio).toInt(),
                scaleSize.height, // (bitmap.height * ratio).toInt(),
                false
            )
        }

        private fun getSampleRatio(imageSize: Size, sampleSize: Size): Int =
            min(imageSize.width / sampleSize.width, imageSize.height / sampleSize.height)

        private fun getSampleSize(imageSize: Size, sampleSize: Size): Size {
            val ratio = getSampleRatio(imageSize, sampleSize)
            return if (ratio > 1) Size(imageSize.width / ratio, imageSize.height / ratio)
            else imageSize
        }
    }

}