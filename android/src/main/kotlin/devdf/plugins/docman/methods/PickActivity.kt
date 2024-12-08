package devdf.plugins.docman.methods

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.widget.Toast
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.ActivityMethodBase
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.extensions.applyMimeTypes
import devdf.plugins.docman.extensions.argAsListString
import devdf.plugins.docman.extensions.copyToCache
import devdf.plugins.docman.extensions.initialUriByMimeType
import devdf.plugins.docman.extensions.initialUriString
import devdf.plugins.docman.extensions.isImageAndVideoTypes
import devdf.plugins.docman.extensions.isImageMimeTypeOnly
import devdf.plugins.docman.extensions.isSingleImageOrVideoType
import devdf.plugins.docman.extensions.isVideoMimeTypeOnly
import devdf.plugins.docman.extensions.toDocumentCache
import devdf.plugins.docman.extensions.toDocumentFile
import devdf.plugins.docman.extensions.toDocumentMap
import devdf.plugins.docman.extensions.toMapResult
import devdf.plugins.docman.utils.DocManBuild
import devdf.plugins.docman.utils.DocManMimeType
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal enum class PickType {
    Directory, Documents, Files, Media;

    companion object {
        fun fromString(str: String?): PickType = when (str) {
            "directory" -> Directory
            "files" -> Files
            "media" -> Media
            else -> Documents
        }
    }
}

internal enum class PickLimitResult {
    Limited, Empty, Cancel, Restart;

    companion object {
        fun fromString(str: String?): PickLimitResult = when (str) {
            "restart" -> Restart
            "empty" -> Empty
            "cancel" -> Cancel
            else -> Limited
        }
    }
}


internal data class PickActivityArgs(
    val type: PickType,
    val mimeTypes: List<String>,
    val localOnly: Boolean,
    val grantPermissions: Boolean,
    val limit: Int,
    val limitResult: PickLimitResult,
    val limitToast: String,
    val imageQuality: Int,
    val usePhotoPicker: Boolean,
    val initDir: String?,
) {
    companion object {
        fun fromMethodCall(call: MethodCall): PickActivityArgs {
            return PickActivityArgs(
                type = PickType.fromString(call.argument("type")),
                mimeTypes = DocManMimeType.combine(
                    call.argAsListString("mimeTypes"),
                    call.argAsListString("extensions")
                ),
                localOnly = call.argument<Boolean>("localOnly") ?: false,
                grantPermissions = call.argument<Boolean>("grantPermissions") ?: true,
                limit = call.argument<Int>("limit") ?: 1,
                limitResult = PickLimitResult.fromString(call.argument("limitType")),
                limitToast = call.argument("limitToast") ?: "Pick limit reached",
                imageQuality = call.argument<Int>("imageQuality") ?: 100,
                usePhotoPicker = call.argument<Boolean>("usePhotoPicker") ?: true,
                initDir = call.argument<String>("initDir")
            )
        }
    }

    @SuppressLint("NewApi") //, "ClassVerificationFailure"
    fun validate(): Pair<String, String>? {
        val maxLimit: Int =
            if (DocManBuild.getPickImagesMaxLimit()) {
                MediaStore.getPickImagesMaxLimit()
            } else 100

        return when (type) {
            PickType.Media -> {
                if (limit > maxLimit) {
                    "_max_limit" to maxLimit.toString()
                } else if (mimeTypes.isNotEmpty() && !mimeTypes.isImageAndVideoTypes()) {
                    "_mimetype" to mimeTypes.toString()
                } else null
            }

            else -> null
        }
    }
}


class PickActivity(
    private val plugin: DocManPlugin,
    call: MethodCall,
    override val result: MethodChannel.Result,
) : ActivityMethodBase {

    private val params: PickActivityArgs = PickActivityArgs.fromMethodCall(call)

    override val meta: DocManMethod = DocManMethod.PickActivity

    /** ACTIVITY METHODS */
    override fun startActivity() {
        //1. Validate the arguments
        params.validate()?.let { error ->
            plugin.queue.finishWithError(requestCode, errorCode + error.first, error.second, null)
            return
        }

        //2. Start the activity
        try {
            plugin.binding?.activity?.startActivityForResult(activityIntent(), requestCode)
        } catch (e: Exception) {
            plugin.queue.finishWithError(
                requestCode,
                "no_activity",
                "pick ${params.type.name.lowercase()}",
                null
            )
        }
    }

    /** Create proper intent by type */
    private fun activityIntent(): Intent {
        return when (params.type) {
            PickType.Directory -> actionOpenDocumentTreeIntent()
            PickType.Media -> if (params.usePhotoPicker) photoPickerIntent() else actionOpenDocumentIntent()
            else -> actionOpenDocumentIntent()
        }
    }

    /** Picking directory intent */
    private fun actionOpenDocumentTreeIntent(): Intent {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        //1. Setting initial directory, if not set,
        // The best option for the user to pick a directory from the External Storage Provider
        // Due to less restrictions and more access to the directories
        intent.initialUriString(
            params.initDir ?: "content://com.android.externalstorage.documents/tree/primary%3A"
        )
        return intent
    }

    /** Picking documents, files & alternative media intent */
    private fun actionOpenDocumentIntent(): Intent {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            if (params.localOnly) putExtra(Intent.EXTRA_LOCAL_ONLY, true)
            if (params.limit > 1) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        //1. Setting mime types
        val mimeTypes = when (params.type) {
            PickType.Media -> params.mimeTypes.ifEmpty { listOf("image/*", "video/*") }
            else -> params.mimeTypes
        }
        //2. If mimeTypes list has only one item, set it as the intent type
        intent.type = if (mimeTypes.size == 1) { // && !mimeTypes.first().endsWith("/*")
            mimeTypes.first()
        } else "*/*"
        //3. Apply mime types
        if (mimeTypes.size > 1) intent.applyMimeTypes(mimeTypes)
        //4. Setting initial directory
        if (params.initDir != null) intent.initialUriString(params.initDir)
        else intent.initialUriByMimeType(mimeTypes)

        return intent
    }

    /** Picking media intent */
    private fun photoPickerIntent(): Intent {
        //1. Detect what media type is required
        val pickMediaType = when {
            params.mimeTypes.isSingleImageOrVideoType() -> ActivityResultContracts.PickVisualMedia.SingleMimeType(
                params.mimeTypes.first()
            )

            params.mimeTypes.isImageMimeTypeOnly() -> ActivityResultContracts.PickVisualMedia.ImageOnly
            params.mimeTypes.isVideoMimeTypeOnly() -> ActivityResultContracts.PickVisualMedia.VideoOnly
            else -> ActivityResultContracts.PickVisualMedia.ImageAndVideo
        }

        val pickMediaRequest = PickVisualMediaRequest(pickMediaType)

        var pickerIntent: Intent = when {
            params.limit > 1 -> ActivityResultContracts.PickMultipleVisualMedia(maxItems = params.limit)
                .createIntent(plugin.context, pickMediaRequest)

            else -> ActivityResultContracts.PickVisualMedia()
                .createIntent(plugin.context, pickMediaRequest)
        }

        if (params.localOnly) pickerIntent.putExtra(Intent.EXTRA_LOCAL_ONLY, true)

        // For older devices running KitKat and higher and devices running Android 12
        // and 13 without the SDK extension that includes the Photo Picker, rely on the
        // ACTION_OPEN_DOCUMENT intent
        // override the pickerIntent fallback with my ACTION_OPEN_DOCUMENT intent
        if (pickerIntent.action == Intent.ACTION_OPEN_DOCUMENT) {
            pickerIntent = actionOpenDocumentIntent()
        }

        return pickerIntent
    }

    /** ACTIVITY RESULT METHODS */
    override fun onActivityResult(resultCode: Int, data: Intent?): Boolean {
        if (resultCode == Activity.RESULT_OK && data != null) {
            val dataUris = mutableSetOf<Uri>()
            //1. Collect uris
            data.data?.let { dataUris.add(it) }
            data.clipData?.let { clip ->
                0.until(clip.itemCount).forEach { index ->
                    clip.getItemAt(index).uri?.let { uri ->
                        dataUris.add(uri)
                    }
                }
            }

            //2. Params Limit & Limit Result
            val uris = limitResults(dataUris) ?: return false
            //3. Recheck set if it's empty return null
            if (uris.isEmpty()) return plugin.queue.finishWithSuccess(requestCode, null)

            CoroutineScope(Dispatchers.IO).launch {
                //4. Process the picked documents
                val result = when (params.type) {
                    PickType.Directory -> processPickedDirectory(uris.first())
                    PickType.Media -> processPickedMedia(uris)
                    else -> processPickedDocuments(uris)
                }

                plugin.queue.finishWithSuccess(requestCode, result)
            }

        } else {
            plugin.queue.finishWithSuccess(requestCode, null)
        }

        return true
    }

    private fun limitResults(uris: MutableSet<Uri>): MutableSet<Uri>? {
        var limitUris = uris
        //1. Check if the limit is reached
        if (params.limit > 1 && uris.size > params.limit) {
            //2. Limit reached
            when (params.limitResult) {
                PickLimitResult.Cancel -> {
                    plugin.queue.finishWithError(
                        requestCode, errorCode + "_count",
                        params.limit.toString(), uris.size.toString()
                    )
                    return null
                }

                PickLimitResult.Empty -> limitUris = mutableSetOf()
                ///Restart the activity
                PickLimitResult.Restart -> {
                    Toast.makeText(plugin.context, params.limitToast, Toast.LENGTH_SHORT).show()
                    startActivity()
                    return null
                }

                else -> {
                    limitUris = uris.take(params.limit).toMutableSet()
                }
            }
        }

        return limitUris
    }

    private suspend fun processPickedDirectory(resultUri: Uri): Map<String, Any?>? {
        return withContext(Dispatchers.IO) {
            //1. Setting permissions
            plugin.permissions.takePersistableUriPermission(resultUri)
            //2. Getting the document file
            val docFile = DocumentFile.fromTreeUri(plugin.context, resultUri)
            //3. Validating && Returning the document file as a map
            when {
                docFile?.exists() == true && docFile.isDirectory -> docFile.toMapResult(plugin.context)
                else -> null
            }
        }
    }

    private suspend fun processPickedDocuments(uris: MutableSet<Uri>): Any {
        //1. Grant permissions if required for the documents
        if (params.grantPermissions) {
            uris.forEach { uri -> plugin.permissions.takePersistableUriPermission(uri) }
        }
        return when (params.type) {
            PickType.Files -> uris.mapNotNull { uri -> uri.toDocumentCache(plugin.context) }
            //Means its PickType.Documents
            else -> uris.mapNotNull { uri -> uri.toDocumentMap(plugin.context) }
        }
    }

    private suspend fun processPickedMedia(uris: MutableSet<Uri>): Any {
        val docs = uris.mapNotNull { uri -> uri.toDocumentFile(plugin.context) }
        return docs.map { doc -> doc.copyToCache(plugin.context, params.imageQuality) }
    }
}