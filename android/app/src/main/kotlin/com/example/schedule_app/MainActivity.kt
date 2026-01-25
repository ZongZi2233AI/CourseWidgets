package com.example.schedule_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val THEME_CHANNEL = "com.zongzi.schedule/theme"
    private val IMAGE_PICKER_CHANNEL = "com.zongzi.schedule/image_picker"
    
    private var pendingResult: MethodChannel.Result? = null
    private val PICK_IMAGE_REQUEST = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 主题色通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, THEME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemAccentColor" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val color = getSystemAccentColor()
                        result.success(color)
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // 图片选择器通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IMAGE_PICKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        // Android 14+ 使用 Photo Picker（不需要权限）
                        pickImageWithPhotoPicker(result)
                    } else {
                        result.error("UNSUPPORTED", "需要 Android 14+", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun getSystemAccentColor(): Int {
        return resources.getColor(android.R.color.system_accent1_500, theme)
    }
    
    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun pickImageWithPhotoPicker(result: MethodChannel.Result) {
        pendingResult = result
        
        // 使用 Android 14+ Photo Picker API
        val intent = Intent(MediaStore.ACTION_PICK_IMAGES).apply {
            type = "image/*"
        }
        
        startActivityForResult(intent, PICK_IMAGE_REQUEST)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == PICK_IMAGE_REQUEST) {
            if (resultCode == RESULT_OK) {
                data?.data?.let { uri ->
                    handleImageUri(uri)
                } ?: pendingResult?.error("NO_IMAGE", "未选择图片", null)
            } else {
                pendingResult?.error("CANCELLED", "用户取消选择", null)
            }
            pendingResult = null
        }
    }
    
    private fun handleImageUri(uri: Uri) {
        try {
            // 将图片复制到应用私有目录
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream == null) {
                pendingResult?.error("READ_ERROR", "无法读取图片", null)
                return
            }
            
            // 创建保存目录
            val appDir = File(filesDir, "backgrounds")
            if (!appDir.exists()) {
                appDir.mkdirs()
            }
            
            // 生成文件名
            val fileName = "bg_${System.currentTimeMillis()}.png"
            val outputFile = File(appDir, fileName)
            
            // 复制文件
            FileOutputStream(outputFile).use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()
            
            // 返回文件路径
            pendingResult?.success(outputFile.absolutePath)
        } catch (e: Exception) {
            pendingResult?.error("SAVE_ERROR", "保存图片失败: ${e.message}", null)
        }
    }
}
