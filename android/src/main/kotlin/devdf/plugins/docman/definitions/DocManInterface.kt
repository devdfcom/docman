package devdf.plugins.docman.definitions

import android.content.Intent
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/** Interface shared across Channels that require `Engine` lifecycle management. */
interface EngineBase {
    fun onAttach()
    fun onDetach()
}

/** Interface shared across Channels that require `Activity` lifecycle management.
 *
 * It extends the [PluginRegistry.ActivityResultListener] interface.
 *
 * @see PluginRegistry.ActivityResultListener
 */
interface ActivityBase : PluginRegistry.ActivityResultListener {
    fun startActivity()
    fun stopActivity()
}

/** Interface shared across Channels that require `Stream` lifecycle management.
 *
 * Extends the [EngineBase] and [StreamHandler] interfaces.
 *
 * @see EngineBase
 * @see StreamHandler
 */
interface EventsBase : EngineBase, StreamHandler

/** Interface for the event methods.
 *
 * Used for methods which uses `DocManChannel.Events` channel.
 * Extends the [MethodMeta] interface.
 *
 * @see MethodMeta
 */
interface EventMethodBase : MethodMeta {
    /// Starts the event stream for the method call.
    suspend fun onListen()
    suspend fun onSuccess(data: Any?)
    suspend fun onError(message: String?, details: Any? = null)
    suspend fun onEnd()

    /// onCancel is fired when the stream is cancelled.
    fun onCancel(arguments: Any?)

}

/** Interface for the activity methods.
 *
 * Used for methods which uses `DocManChannel.Activity` channel.
 * Extends the [MethodBase] interface.
 *
 * @see MethodBase
 */
interface ActivityMethodBase : MethodBase {
    /** Starts the activity for the method call.
     * Commonly used for configuring the intent and starting the activity.
     */
    fun startActivity()

    /** Handles the result of the activity.
     *
     * @param resultCode The result code of the activity.
     * @param data The data received from the activity.
     * @return Boolean - Return true if the result is processed successfully, otherwise false.
     */
    fun onActivityResult(resultCode: Int, data: Intent?): Boolean
}

/** Interface for the action methods.
 *
 * Used for methods which uses `DocManChannel.Action` channel.
 * Extends the [MethodBase] interface.
 *
 * @see MethodBase
 */
interface ActionMethodBase : MethodBase {
    fun oMethodCall()
}

/** Helper interface for the queued method calls.
 *
 * This interface is used to manage the method calls in the queue.
 * Under the hood, it uses `MethodChannel.Result` to send the result back to the Flutter side.
 *
 * @property success (data: Any?) -> Unit - The success callback for the method.
 * @property onError (message: String?, details: Any?) -> Unit - The error callback for the method.
 */
interface QueuedMethod {
    fun success(data: Any?)
    fun onError(message: String?, details: Any? = null)
}

/** Interface for the method calls, and manages the method calls in it.
 *
 * This is the base interface for all the method calls.
 * It extends the [MethodMeta] interface.
 *
 * @property result `MethodChannel.Result` - The result object.
 * @see MethodMeta
 */
interface MethodBase : MethodMeta {
    val result: MethodChannel.Result
}

/** Interface for the method calls, and manages the method calls in it.
 *
 * This is the base interface for all calls.
 * It declares the basic properties that are required.
 *
 * @property meta [DocManMethod] - The method meta data.
 * @property tag The log tag for the method.
 * @property errorCode The error code for the method, used when throwing exceptions.
 * @property method The name of the method used in Flutter.
 * @property requestCode The request code of the method call.
 * It's `ordinal` from the [DocManMethod] enum.
 */
interface MethodMeta {
    val meta: DocManMethod
    val tag: String
        get() = meta.logTag
    val errorCode: String
        get() = meta.errorCode
    val method: String
        get() = meta.methodName
    val requestCode: String
        get() = meta.requestCode.toString()
}



