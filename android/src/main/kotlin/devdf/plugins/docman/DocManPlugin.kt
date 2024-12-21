package devdf.plugins.docman

import android.content.Context
import devdf.plugins.docman.channels.DocManActions
import devdf.plugins.docman.channels.DocManActivity
import devdf.plugins.docman.channels.DocManEvents
import devdf.plugins.docman.utils.DocManPermissionsManager
import devdf.plugins.docman.utils.DocManQueueManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

/** DocmanPlugin */
class DocManPlugin : FlutterPlugin, ActivityAware {

    companion object {
        ///Base name for the channels
        const val MAIN_CHANNEL = "devdf.plugins/docman"
    }

    /// Manage channels
    private val docManActivity = DocManActivity(this)
    private val docManActions = DocManActions(this)
    private val docManEvents = DocManEvents(this)

    /// Utilize permissions, queue
    val permissions = DocManPermissionsManager(this)
    val queue = DocManQueueManager()

    lateinit var context: Context
    var binding: ActivityPluginBinding? = null
    var messenger: BinaryMessenger? = null


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        //1. Setting the context and messenger
        context = binding.applicationContext
        messenger = binding.binaryMessenger
        //2. Attaching the activity
        docManActivity.onAttach()
        //3. Attaching the actions
        docManActions.onAttach()
        //4. Attaching stream events
        docManEvents.onAttach()
        //5. Clearing cache temporary directories
//        DocManFiles.clearCacheDirectories(context)
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        docManActivity.onDetach()
        docManActions.onDetach()
        docManEvents.onDetach()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding

        docManActivity.startActivity()
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.binding = binding
    }

    override fun onDetachedFromActivity() {
        binding = null
    }
}
