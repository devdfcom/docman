package devdf.plugins.docman.definitions

import devdf.plugins.docman.DocManPlugin

/** Declares the channel names for the plugin */
enum class DocManChannel {
    /// Channel used for all actions on Files, Directories,
    // which are not require Activity lifecycle management
    Action,

    /// Channel used for all interactions with Android Intents
    Activity,

    /// Channel used for stream events like directory file list, file save, file read, etc.
    Events;

    /// Returns the full channel name
    val channelName: String
        get() = DocManPlugin.MAIN_CHANNEL + "/" + name.lowercase()
}