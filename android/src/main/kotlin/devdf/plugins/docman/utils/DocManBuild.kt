package devdf.plugins.docman.utils

import android.os.Build
import android.os.ext.SdkExtensions.getExtensionVersion
import androidx.annotation.ChecksSdkIntAtLeast

/**  Utility class to check for build version and features */
class DocManBuild {
    companion object {
        /** Can Set initial uri from string for Intent */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.R)
        fun initialUriString(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

        /** Can Set initial uri by mime type for Intent */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.O)
        fun initialUriByMimeType(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O

        /** Can Set initial uri by mime type for Intent as Downloads URI  */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.Q)
        fun initialUriByMimeTypeDownloads(): Boolean =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

        /** Can use `DocumentsContract.isTreeUri` */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.N)
        fun isTreeUri(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N

        /** Can create Intent as Chooser  */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.LOLLIPOP_MR1)
        fun intentAsChooser(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1

        /** MediaStore.getPickImagesMaxLimit()
         *
         * Is supported on Android Tiramisu and above or
         * on Android R Extensions 2. */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.R, extension = 2)
        fun getPickImagesMaxLimit(): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                true
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // getExtension is seen as part of Android Tiramisu only while the SdkExtensions
                // have been added on Android R
                getExtensionVersion(Build.VERSION_CODES.R) >= 2
            } else false
        }

        /** Can use `Bitmap.CompressFormat.WEBP_LOSSLESS` */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.R)
        fun newCompressFormatWEBP(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

        /** Can use `MediaMetadataRetriever.getScaledFrameAtTime` */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.P)
        fun getScaledFrameAtTime(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P

        /** Can use `ImageDecoder` */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.P)
        fun canUseImageDecoder(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P

        /** Can use `ContentResolver.loadThumbnail` */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.Q)
        fun loadThumbnail(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

        /** Can use `DocumentsContract.Document.FLAG_SUPPORTS_MOVE` */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.N)
        fun supportsMoveCopyFlag(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N

        /** Can use `DocumentsContract.Root.FLAG_EMPTY` */
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.Q)
        fun supportsRootEmptyFlag(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
    }
}