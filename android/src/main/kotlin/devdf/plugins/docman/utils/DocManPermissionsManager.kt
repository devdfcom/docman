package devdf.plugins.docman.utils

import android.content.Intent
import android.content.UriPermission
import android.net.Uri
import devdf.plugins.docman.DocManPlugin
import devdf.plugins.docman.extensions.isTreeUri

/** This class is used to manage the permissions that are available to the plugin
 *
 *  Persistable permissions have limitations:
 *  - Limited to 128 permissions per app for Android 10 and below
 *  - Limited to 512 permissions per app for Android 11 and above
 * */
class DocManPermissionsManager(private val plugin: DocManPlugin) {

    //TODO - Add a method to verify if list is almost full,
    // release oldest permission before adding new one
    // or maybe release all document permissions which are not directories


    companion object {
        const val READ_FLAG = Intent.FLAG_GRANT_READ_URI_PERMISSION
        const val WRITE_FLAG = Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    }

    /** This method is used to take persistable permission for `Uri`,
     * commonly used for granting access to picked directory, etc.
     *
     *  @param uri [Uri] to take permission for.
     *  @throws SecurityException if the permission is not granted
     * */
    @Throws(SecurityException::class)
    fun takePersistableUriPermission(uri: Uri) {
        plugin.context.contentResolver.takePersistableUriPermission(
            uri,
            READ_FLAG or WRITE_FLAG
        )
    }

    /** Get all the persisted permissions for the plugin.
     * If there are no persisted permissions, it returns an empty list.
     *
     * @param dirs Include directories in the list
     * @param files Include files in the list
     *
     * @return [List] of [UriPermission]
     */
    fun getAll(dirs: Boolean = true, files: Boolean = true): List<UriPermission> {
        return plugin.context.contentResolver.persistedUriPermissions.filter {
            (dirs && files) || (dirs && it.uri.isTreeUri()) || (files && !it.uri.isTreeUri())
        }
    }

    /** Release all the persisted permissions for the plugin. */
    fun releaseAll() = getAll().forEach(::release)

    /** Release the permission.
     *
     * @param perm [UriPermission] to release
     * @return [List] of [UriPermission]
     * @throws SecurityException if the permission is not granted
     */
    @Throws(SecurityException::class)
    fun release(perm: UriPermission) {
        plugin.context.contentResolver.releasePersistableUriPermission(
            perm.uri,
            READ_FLAG or WRITE_FLAG
        )
    }

//    /** Check if uri is persisted, in list of `persistedUriPermissions`.
//     * If it is, return the [UriPermission] object with granted permissions.
//     *
//     * @param uri [Uri] to check if it is persisted
//     * @return [UriPermission] if it is in list, else null
//     */
//    fun status(uri: Uri): UriPermission? {
//        return plugin.context.contentResolver.persistedUriPermissions.find { it.uri == uri }
//    }

}