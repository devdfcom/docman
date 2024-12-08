package devdf.plugins.docman.extensions

import android.net.Uri
import java.io.File


/** Convert string to URI */
fun String.toUri(): Uri {
    val parsed = Uri.parse(this)
    val parsedScheme: String? = parsed.scheme

    return if (parsedScheme.isNullOrEmpty() || ("${this[0]}" == "/")) {
        try {
            Uri.fromFile(File(this))
        } catch (e: Exception) {
            parsed
        }
    } else parsed
}

/** Sanitize string to be used as a file name */
fun String.asFileName(): String =
    this.replace(Regex("[\\\\/:*?\"<>|\\[\\]\\s]"), "_")