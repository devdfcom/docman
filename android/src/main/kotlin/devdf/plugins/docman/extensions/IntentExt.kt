package devdf.plugins.docman.extensions

import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import devdf.plugins.docman.utils.DocManBuild


/**
 * Try to set the initial directory for the file picker / saver / directory picker.
 * Used for `ACTION_OPEN_DOCUMENT`, `ACTION_CREATE_DOCUMENT`, `ACTION_OPEN_DOCUMENT_TREE`.
 *
 * @param initDir The initial directory to set.
 * Location should specify a `document URI` or a `tree URI` with `document ID`.
 * If this URI identifies a non-directory, document navigator will attempt to use the parent of the document as the initial location.
 * Must be a valid URI string or null.
 * This is only supported on Android Oreo and above.
 */
fun Intent.initialUriString(initDir: String?) {
    if (DocManBuild.initialUriString() && initDir != null) {
        putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse(initDir))
    }
}

/** Try to guess the initial directory by mime type list.
 * Used for `ACTION_OPEN_DOCUMENT`, `ACTION_CREATE_DOCUMENT`.
 *
 * @param mimeTypes The list of mime types to filter.
 * This is only supported on Android Oreo and above.
 */
fun Intent.initialUriByMimeType(mimeTypes: List<String>) {
    if (DocManBuild.initialUriByMimeType()) {
        val uri = when {
            mimeTypes.isImageMimeTypeOnly() -> android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            mimeTypes.isVideoMimeTypeOnly() -> android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            mimeTypes.isAudioMimeTypeOnly() -> android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            DocManBuild.initialUriByMimeTypeDownloads() -> android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI
            else -> null
        }
        uri?.let { putExtra(DocumentsContract.EXTRA_INITIAL_URI, it) }
    }
}

/**
 * Apply mime types filter to the intent.
 * Used commonly for `ACTION_OPEN_DOCUMENT`, `ACTION_GET_CONTENT`.
 *
 * @param mimeTypesFilter The list of mime types to filter.
 * If this is not null or empty, only documents that match one of the given MIME types are shown.
 */
fun Intent.applyMimeTypes(mimeTypesFilter: List<String>?) {
    if (!mimeTypesFilter.isNullOrEmpty()) {
        putExtra(Intent.EXTRA_MIME_TYPES, mimeTypesFilter.toTypedArray())
    }
}

/**
 * Trying to convert to `ACTION_CHOOSE` intent with a title.
 * Used commonly for `ACTION_SEND`, `ACTION_VIEW`, `ACTION_GET_CONTENT`.
 * This is only supported on Android Lollipop MR1 and above.
 *
 * @param title The title to set for the chooser dialog.
 * If this is null, the empty title will be used.
 *
 * @return The chooser intent with the title set, or the intent as is.
 */
fun Intent.asChooser(title: String?): Intent = when {
    DocManBuild.intentAsChooser() -> Intent.createChooser(this, title)
    else -> this
}