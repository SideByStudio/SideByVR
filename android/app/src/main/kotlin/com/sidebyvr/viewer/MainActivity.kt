package com.sidebyvr.viewer

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val EVENT_CHANNEL = "com.sidebyvr.viewer/gamepad_events"
    private val STORAGE_CHANNEL = "com.sidebyvr.viewer/storage"
    private val PICK_DIRECTORY_REQUEST = 2407

    private var eventSink: EventChannel.EventSink? = null
    private var pendingDirectoryResult: MethodChannel.Result? = null
    private var lastHatXDirection = 0
    private var lastHatYDirection = 0

    @SuppressLint("RestrictedApi")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel: 实时推送摇杆事件到 Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            handleStorageCall(call, result)
        }

    }

    private fun handleStorageCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "pickDirectory" -> pickDirectory(call, result)
                "hasPersistedAccess" -> {
                    val uri = Uri.parse(requireString(call, "uri"))
                    result.success(hasPersistedAccess(uri))
                }
                "listChildren" -> {
                    val uri = Uri.parse(requireString(call, "uri"))
                    result.success(listChildren(uri))
                }
                "getDocumentInfo" -> {
                    val uri = Uri.parse(requireString(call, "uri"))
                    result.success(documentInfo(uri))
                }
                "getParentDirectory" -> {
                    val rootUri = Uri.parse(requireString(call, "rootUri"))
                    val currentUri = Uri.parse(requireString(call, "currentUri"))
                    result.success(parentDirectory(rootUri, currentUri))
                }
                "copyDocumentToCache" -> {
                    val uri = Uri.parse(requireString(call, "uri"))
                    val bucket = call.argument<String>("bucket") ?: "saf"
                    val fileName = call.argument<String>("fileName") ?: "media"
                    result.success(copyDocumentToCache(uri, bucket, fileName))
                }
                "openExternalUrl" -> {
                    val url = call.argument<String>("url")
                        ?: throw IllegalArgumentException("Missing url")
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error(
                "STORAGE_ERROR",
                error.message ?: error.javaClass.simpleName,
                null,
            )
        }
    }

    private fun requireString(call: MethodCall, name: String): String =
        call.argument<String>(name)
            ?: throw IllegalArgumentException("Missing $name")

    private fun pickDirectory(call: MethodCall, result: MethodChannel.Result) {
        if (pendingDirectoryResult != null) {
            result.error("PICK_IN_PROGRESS", "A directory picker is already open", null)
            return
        }
        pendingDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
            call.argument<String>("initialUri")?.let {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse(it))
            }
        }
        startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
    }



    @Deprecated("Used for ACTION_OPEN_DOCUMENT_TREE compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_DIRECTORY_REQUEST) return

        val result = pendingDirectoryResult
        pendingDirectoryResult = null
        if (result == null) return
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result.success(null)
            return
        }

        val takeFlags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        contentResolver.takePersistableUriPermission(treeUri, takeFlags)
        result.success(documentInfo(treeUri))
    }

    private fun hasPersistedAccess(uri: Uri): Boolean =
        contentResolver.persistedUriPermissions.any {
            it.isReadPermission && it.uri == uri
        }

    private fun documentId(uri: Uri): String = try {
        DocumentsContract.getDocumentId(uri)
    } catch (_: IllegalArgumentException) {
        DocumentsContract.getTreeDocumentId(uri)
    }

    private fun documentUri(uri: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(uri, documentId(uri))

    private fun documentInfo(uri: Uri): Map<String, Any?> {
        val resolvedUri = if (DocumentsContract.isTreeUri(uri)) documentUri(uri) else uri
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        contentResolver.query(resolvedUri, projection, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) {
                throw IllegalStateException("Directory is no longer available")
            }
            val mimeType = cursor.getString(1)
            return mapOf(
                "uri" to uri.toString(),
                "name" to (cursor.getString(0) ?: "Selected folder"),
                "isDirectory" to
                    (mimeType == DocumentsContract.Document.MIME_TYPE_DIR),
                "mimeType" to mimeType,
                "size" to if (cursor.isNull(2)) null else cursor.getLong(2),
                "lastModified" to if (cursor.isNull(3)) null else cursor.getLong(3),
            )
        }
        throw IllegalStateException("Unable to read selected directory")
    }

    private fun listChildren(parentUri: Uri): List<Map<String, Any?>> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            parentUri,
            documentId(parentUri),
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        val items = mutableListOf<Map<String, Any?>>()
        val cursor = contentResolver.query(
            childrenUri,
            projection,
            null,
            null,
            null,
        ) ?: throw IllegalStateException("Directory is no longer available")
        cursor.use {
            while (cursor.moveToNext()) {
                val childUri = DocumentsContract.buildDocumentUriUsingTree(
                    parentUri,
                    cursor.getString(0),
                )
                val mimeType = cursor.getString(2)
                items.add(
                    mapOf(
                        "uri" to childUri.toString(),
                        "name" to (cursor.getString(1) ?: "Unnamed"),
                        "isDirectory" to
                            (mimeType == DocumentsContract.Document.MIME_TYPE_DIR),
                        "mimeType" to mimeType,
                        "size" to if (cursor.isNull(3)) null else cursor.getLong(3),
                        "lastModified" to
                            if (cursor.isNull(4)) null else cursor.getLong(4),
                    ),
                )
            }
        }
        return items
    }

    private fun parentDirectory(rootUri: Uri, currentUri: Uri): Map<String, Any?>? {
        val rootId = DocumentsContract.getTreeDocumentId(rootUri)
        val currentId = documentId(currentUri)
        if (currentId == rootId) return null
        val slash = currentId.lastIndexOf('/')
        val parentId = if (slash >= 0) currentId.substring(0, slash) else rootId
        if (!parentId.startsWith(rootId)) return null
        val parentUri = DocumentsContract.buildDocumentUriUsingTree(rootUri, parentId)
        return documentInfo(parentUri)
    }

    private fun safeSegment(value: String, fallback: String): String {
        val cleaned = value
            .replace(Regex("[\\\\/:*?\"<>|\\u0000-\\u001F]"), "_")
            .replace("..", "_")
            .trim()
        return cleaned.ifBlank { fallback }
    }

    private fun copyDocumentToCache(
        uri: Uri,
        bucket: String,
        fileName: String,
    ): String {
        val safeBucket = safeSegment(bucket, "saf")
        val safeName = safeSegment(fileName, "media")
        val destination = File(File(cacheDir, "saf"), safeBucket).apply {
            mkdirs()
        }
        val output = File(destination, safeName)
        contentResolver.openInputStream(uri)?.use { input ->
            output.outputStream().use { target ->
                input.copyTo(target, 1024 * 1024)
            }
        } ?: throw IllegalStateException("Unable to open selected document")
        return output.absolutePath
    }

    override fun onResume() {
        super.onResume()
        // 确保窗口获取焦点，让 onGenericMotionEvent 立即接收手柄摇杆事件
        window.decorView.isFocusableInTouchMode = true
        window.decorView.requestFocus()
    }



    /** D-Pad/LB may arrive as KeyEvent; forward them independently of focus. */
    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        val direction = when (keyCode) {
            KeyEvent.KEYCODE_DPAD_LEFT -> "left"
            KeyEvent.KEYCODE_DPAD_RIGHT -> "right"
            KeyEvent.KEYCODE_DPAD_UP -> "up"
            KeyEvent.KEYCODE_DPAD_DOWN -> "down"
            else -> null
        }
        if (direction != null && eventSink != null) {
            eventSink?.success(mapOf("dpad" to direction))
            return true
        }
        if (keyCode == KeyEvent.KEYCODE_BUTTON_L1 && eventSink != null) {
            if (event.repeatCount == 0) {
                eventSink?.success(mapOf("button" to "lb"))
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    /**
     * 拦截游戏手柄的 MotionEvent（摇杆、扳机等）
     * Android 系统会将摇杆的模拟轴值通过 MotionEvent 发送
     */
    @SuppressLint("RestrictedApi")
    override fun onGenericMotionEvent(event: MotionEvent): Boolean {
        val source = event.source
        if ((source and InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK ||
            (source and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD) {

            // 读取左摇杆 AXIS_X(0), AXIS_Y(1)
            val newLeftX = event.getAxisValue(MotionEvent.AXIS_X)
            val newLeftY = event.getAxisValue(MotionEvent.AXIS_Y)
            // 读取右摇杆 AXIS_Z(11), AXIS_RZ(14)
            val newRightX = event.getAxisValue(MotionEvent.AXIS_Z)
            val newRightY = event.getAxisValue(MotionEvent.AXIS_RZ)
            // Some controllers expose their circular D-Pad as HAT axes.
            val newHatX = event.getAxisValue(MotionEvent.AXIS_HAT_X)
            val newHatY = event.getAxisValue(MotionEvent.AXIS_HAT_Y)

            // Turn a continuous HAT axis into one D-Pad action per press.
            val hatXDirection = when {
                newHatX < -0.5f -> -1
                newHatX > 0.5f -> 1
                else -> 0
            }
            val hatYDirection = when {
                newHatY < -0.5f -> -1
                newHatY > 0.5f -> 1
                else -> 0
            }
            if (hatXDirection != 0 && hatXDirection != lastHatXDirection) {
                eventSink?.success(mapOf(
                    "dpad" to if (hatXDirection < 0) "left" else "right",
                ))
            }
            if (hatYDirection != 0 && hatYDirection != lastHatYDirection) {
                eventSink?.success(mapOf(
                    "dpad" to if (hatYDirection < 0) "up" else "down",
                ))
            }
            lastHatXDirection = hatXDirection
            lastHatYDirection = hatYDirection

            // 死区处理 (deadzone 0.1)
            val deadzone = 0.1f
            val leftX = if (Math.abs(newLeftX) > deadzone) newLeftX else 0f
            val leftY = if (Math.abs(newLeftY) > deadzone) newLeftY else 0f
            val rightX = if (Math.abs(newRightX) > deadzone) newRightX else 0f
            val rightY = if (Math.abs(newRightY) > deadzone) newRightY else 0f

            // 推送到 Flutter
            eventSink?.success(mapOf(
                "leftX" to leftX,
                "leftY" to leftY,
                "rightX" to rightX,
                "rightY" to rightY
            ))

            return true
        }

        return super.onGenericMotionEvent(event)
    }
}
