package devdf.plugins.docman.extensions

import android.content.UriPermission

/** Convert [UriPermission] to Map */
fun UriPermission.toMap(): Map<String, Any?> = mapOf(
    "uri" to uri.toString(),
    "read" to isReadPermission,
    "write" to isWritePermission,
    "time" to persistedTime,
)