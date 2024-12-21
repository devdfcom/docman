package devdf.plugins.docman.extensions

import java.io.File

/** Check if file can be used to generate a thumbnail */
fun File.canThumbnail(): Boolean {
    return name.getMimeTypeByExtension().let {
        it == "application/pdf" || it.startsWith("image/") || it.startsWith("video/")
    }
}

/** Check if file is a video file by extension mimeType */
fun File.isVideo(): Boolean {
    return name.getMimeTypeByExtension().startsWith("video/")
}

/** Get thumbnail name for the file
 *
 * @param name Name to be used for the thumbnail or null.
 * If null, the file name will be used
 * @return Thumbnail name for the file.
 * Example: thumb_file_name.jpg
 */
fun File.getThumbnailName(name: String?): String {
    //1. To create unique thumbnail name, use relative path, convert to lowercase and replace spaces
    val uniqueName =
        (name?.substringBeforeLast(".") ?: nameWithoutExtension).asFileName().lowercase()
    return "$uniqueName.jpg"
}

