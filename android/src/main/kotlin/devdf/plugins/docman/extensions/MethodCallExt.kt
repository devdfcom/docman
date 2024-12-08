package devdf.plugins.docman.extensions

import io.flutter.plugin.common.MethodCall


/**
 * Extension function for `MethodCall` to retrieve an argument as a list of strings.
 *
 * @param key The key for the argument to retrieve.
 * @return A list of strings if the argument exists and is a list, otherwise null.
 */
fun MethodCall.argAsListString(key: String): List<String>? {
    return if (hasArgument(key)) {
        argument<ArrayList<String>>(key)?.toList()
    } else null
}

/**
 * Extension function for `MethodCall` to retrieve an argument as a set of strings.
 *
 * @param key The key for the argument to retrieve.
 * @return A set of strings if the argument exists and is a list, otherwise null.
 */
fun MethodCall.argAsSetString(key: String): Set<String>? = argAsListString(key)?.toSet()

/**
 * Extension function for `MethodCall` to retrieve an argument as a map of strings.
 *
 * @param key The key for the argument to retrieve.
 * @return A map of strings if the argument exists and is a map, otherwise null.
 */
fun MethodCall.argAsMap(key: String): Map<String, Any?>? {
    return if (hasArgument(key)) {
        argument<Map<String, Any?>>(key)
    } else null
}

/**
 * Extension function for `MethodCall` to retrieve all arguments as a map.
 *
 * @return A map `Map<String, Any?>` if the call has arguments, otherwise null.
 */
fun MethodCall.argsAsMap(): Map<String, Any?>? = arguments<Map<String, Any?>>()