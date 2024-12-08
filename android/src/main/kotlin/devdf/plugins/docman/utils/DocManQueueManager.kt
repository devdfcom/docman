package devdf.plugins.docman.utils

import devdf.plugins.docman.definitions.MethodBase
import devdf.plugins.docman.extensions.alreadyRunning

/** Queue for the method calls, and manages the method calls in it. */
class DocManQueueManager {
    val queue: MutableMap<Int, MethodBase> = mutableMapOf()

    /** Adds method to the queue with validation.
     * If the method is already in the queue, set result as error,
     * with message `MethodChannel.Result.alreadyRunning`
     *
     * @param method MethodBase
     * @return true if the method is added to the queue, false otherwise
     */
    fun add(method: MethodBase): Boolean {
        if (queue.containsKey(method.requestCode)) {
            method.result.alreadyRunning(method.method)
            return false
        } else {
            queue[method.requestCode] = method
            return true
        }
    }

    /** Finish the method call with the result.
     * This will send success result for the method call,
     * and remove the method call from the queue.
     *
     * @param requestCode The request code of the method call.
     * It's `ordinal` from the `DocManMethod` enum.
     * @param result Any data to send as result.
     * @return true if the method call is removed from the queue, false otherwise.
     */
    fun finishWithSuccess(requestCode: Int, result: Any?): Boolean {
        //1. Send the result
        method(requestCode)?.result?.success(result)
        //2. Remove the method call from the queue
        return remove(requestCode) != null
    }

    /** Finish the method call with the error.
     * This will finish the method call and remove the method call from the queue.
     *
     * @param request The request code of the method call.
     * It's `ordinal` from the `DocManMethod` enum.
     * @param code The error code.
     * @param message The error message.
     * @param details Any details to send with the error.
     * @return true if the method call is removed from the queue, false otherwise.
     */
    fun finishWithError(
        request: Int,
        code: String,
        message: String?,
        details: Any?
    ): Boolean {
        //1. Send the error
        method(request)?.result?.error(code, message, details)
        //2. Remove the method call from the queue
        return remove(request) != null
    }

    /** Finish the method call with the error.
     * This will finish the method call with set result as error,
     * with message `MethodChannel.Result.notImplemented`
     * and remove the method call from the queue.
     *
     * @param requestCode The request code of the method call.
     * It's `ordinal` from the `DocManMethod` enum.
     * @return true if the method call is removed from the queue, false otherwise.
     */
    fun finishNotImplemented(requestCode: Int): Boolean {
        //1. Send the error
        method(requestCode)?.result?.notImplemented()
        //2. Remove the method call from the queue
        return remove(requestCode) != null
    }


    /** Remove the method call from the queue.
     *
     * @param requestCode The request code of the method call.
     * It's `ordinal` from the `DocManMethod` enum.
     * @return  The method that was removed from the queue.
     */
    fun remove(requestCode: Int): MethodBase? =
        queue.remove(requestCode)

    /** Get the method call from the queue with the [requestCode]
     *
     * @param requestCode The request code of the method call.
     * It's `ordinal` from the `DocManMethod` enum.
     * @return The method call.
     * */
    fun method(requestCode: Int): MethodBase? = queue[requestCode]

    /** Get the method call from the queue with the [requestCode]
     *
     * @param requestCode The request code of the method call.
     * It's `ordinal` from the `DocManMethod` enum.
     * @return The method call casted to the [T] type.
     * */
    inline fun <reified T : MethodBase> methodCast(requestCode: Int): T? {
        return queue[requestCode] as? T
    }
}