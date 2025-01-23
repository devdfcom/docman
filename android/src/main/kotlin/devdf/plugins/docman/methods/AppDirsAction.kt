package devdf.plugins.docman.methods

import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.definitions.ActionMethodBase
import devdf.plugins.docman.definitions.DocManMethod
import devdf.plugins.docman.definitions.QueuedMethod
import devdf.plugins.docman.utils.DocManFiles
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.util.PathUtils

enum class AppDirType {
    /** Cache directory of the app, usually `/data/data/package.name`  */
    Cache,
    Files,

    /** Used to get the data directory of the app,
     * usually it's `package.name/app_flutter` directory */
    Data,
    CacheExt,
    FilesExt;

    companion object {
        fun fromString(name: String?): AppDirType? =
            values().find { it.name.lowercase() == name }
    }
}

class AppDirsAction(
    private val plugin: DocManPlugin,
    private val call: MethodCall,
    override val result: MethodChannel.Result,
) : ActionMethodBase, QueuedMethod {

    override val meta: DocManMethod = DocManMethod.AppDirs

    private val dir = AppDirType.fromString(call.argument<String>("dir"))

    private val action = call.argument<String>("action")

    override fun oMethodCall() {
        when (action) {
            "path" -> getPath()
            "clear" -> clear()
            "all" -> getAll()
            else -> notImplementedAction(action)
        }
    }

    private fun getPath() {
        val dirPath = when (dir) {
            AppDirType.Cache -> plugin.context.cacheDir.path
            AppDirType.Files -> plugin.context.filesDir.path
            AppDirType.Data -> PathUtils.getDataDirectory(plugin.context)
            AppDirType.CacheExt -> plugin.context.externalCacheDir?.path
            AppDirType.FilesExt -> plugin.context.getExternalFilesDir(null)?.path
            else -> null
        }

        dirPath?.let { success(it) } ?: dirPathError()
    }


    private fun clear() {
        // Clear the cache directory, currently only cache directory is supported
        if (dir == AppDirType.Cache) DocManFiles.clearCacheDirectories(plugin.context)
        success(true)
    }

    private fun getAll() {
        val dirs = mutableMapOf<String, String>(
            "cache" to plugin.context.cacheDir.path,
            "files" to plugin.context.filesDir.path,
            "data" to PathUtils.getDataDirectory(plugin.context),
            "cacheExt" to (plugin.context.externalCacheDir?.path ?: ""),
            "filesExt" to (plugin.context.getExternalFilesDir(null)?.path ?: "")
        )

        success(dirs)
    }

    private fun dirPathError() {
        plugin.queue.finishWithError(
            requestCode,
            errorCode + "_path",
            call.argument<String>("dir"),
            null
        )
    }

    private fun notImplementedAction(action: String?) {
        plugin.queue.finishWithError(requestCode, errorCode + "_action", action, null)
    }

    override fun success(data: Any?) {
        plugin.queue.finishWithSuccess(requestCode, data)
    }

    override fun onError(message: String?, details: Any?) {
        plugin.queue.finishWithError(requestCode, errorCode, message, details)
    }
}