package devdf.plugins.docman.extensions

/** Check if list contains only image mime types */
fun List<String>.isImageMimeTypeOnly(): Boolean =
    this.isNotEmpty() && this.all { it.startsWith("image/") }

/** Check if list contains only video mime types */
fun List<String>.isVideoMimeTypeOnly(): Boolean =
    this.isNotEmpty() && this.all { it.startsWith("video/") }

/** Check if list contains only audio mime types */
fun List<String>.isAudioMimeTypeOnly(): Boolean =
    this.isNotEmpty() && this.all { it.startsWith("audio/") }

/** Check if list contains visual media mime types only - images & videos */
fun List<String>.isImageAndVideoTypes(): Boolean =
    this.isNotEmpty() && this.all { it.startsWith("image/") || it.startsWith("video/") }

/*Check if list contains only 1 mimetype & it is image or video without asterisk */
fun List<String>.isSingleImageOrVideoType(): Boolean =
    this.isNotEmpty() && this.size == 1
            && (this[0].startsWith("image/") || this[0].startsWith("video/"))
            && !this[0].contains("*")