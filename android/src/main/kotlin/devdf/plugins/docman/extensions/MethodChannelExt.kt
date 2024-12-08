package devdf.plugins.docman.extensions

import io.flutter.plugin.common.MethodChannel

/** Return an error when a method call is already in queue
 *
 * - errorCode: "already_running"
 * - errorMessage: "Method: $methodName is already running"
 * - errorDetails: null
 * */
fun MethodChannel.Result.alreadyRunning(methodName: String?) {
    error("already_running", methodName, "Method: $methodName is already running")
}