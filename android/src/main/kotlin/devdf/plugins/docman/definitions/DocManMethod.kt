package devdf.plugins.docman.definitions

/**
 * Enum class representing all methods used in plugin.
 *
 * @property channel The channel associated with the method.
 * @property logTag The log tag for the method.
 * @property methodName The name of the method used in Flutter.
 * @property requestCode is the ordinal value of the enum constant.
 */
enum class DocManMethod(
    /// The channel associated with the method
    val channel: DocManChannel,
    /// The log tag for the method
    val logTag: String,
    /// The code used for error result
    val errorCode: String,
) {

    /**
     * Method for picking activity, like directory, documents, files, visualMedia.
     *
     * @property channel [DocManChannel.Activity].
     * @property requestCode is the ordinal value of the enum constant.
     */
    PickActivity(DocManChannel.Activity, "PickActivity", "picker"),
    DocumentFileActivity(DocManChannel.Activity, "DocumentFileActivity", "document_file"),

    /**
     * Method for working with permissions.
     *
     * @property channel [DocManChannel.Action].
     * @property logTag `PermissionsAction`.
     * @property methodName `permissions`.
     * @property requestCode is the ordinal value of the enum constant.
     */
    Permissions(DocManChannel.Action, "PermissionsAction", "permissions"),
    AppDirs(DocManChannel.Action, "AppDirsAction", "app_dirs"),
    DocumentFileAction(DocManChannel.Action, "DocumentFileAction", "document_file"),

    /** Method for working with document files via stream events. */
    DocumentFileEvent(DocManChannel.Events, "DocumentFileEvent", "document_file"),

    /** Method for working with permissions via stream events. */
    PermissionsEvent(DocManChannel.Events, "PermissionsEvent", "permissions");


    companion object {
        fun fromMethodName(name: String): DocManMethod? =
            values().find { it.methodName == name }
    }

    val methodName: String
        get() = name.lowercase()

    val requestCode: Int
        get() = ordinal
}