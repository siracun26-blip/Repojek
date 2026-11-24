#!/bin/bash
# Script Generator Proyek Android Siap Build di GitHub Actions (dengan GitHub Secrets)
# Kompatibel mulai Android 5.0 (SDK 21) hingga Android terbaru
# Jalankan: bash setup_github_project.sh

PROJECT_DIR="AIVideoTranslatorGithub"
PKG_PATH="$PROJECT_DIR/app/src/main/java/com/example/videotranslator"
RES_LAYOUT_PATH="$PROJECT_DIR/app/src/main/res/layout"
RES_VALUES_PATH="$PROJECT_DIR/app/src/main/res/values"
GITHUB_WORKFLOW_PATH="$PROJECT_DIR/.github/workflows"

echo "Membuat struktur direktori proyek untuk GitHub Actions..."
mkdir -p "$PKG_PATH"
mkdir -p "$RES_LAYOUT_PATH"
mkdir -p "$RES_VALUES_PATH"
mkdir -p "$GITHUB_WORKFLOW_PATH"

# 1. GitHub Actions Workflow (.github/workflows/build-apk.yml)
cat << 'EOF' > "$GITHUB_WORKFLOW_PATH/build-apk.yml"
name: Build Android APK

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v3
        with:
          gradle-version: '8.2.1'

      - name: Build Debug APK
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: gradle assembleDebug --stacktrace

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: AI-Video-Translator-APK
          path: app/build/outputs/apk/debug/app-debug.apk
EOF

# 2. .gitignore
cat << 'EOF' > "$PROJECT_DIR/.gitignore"
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
local.properties
EOF

# 3. settings.gradle
cat << 'EOF' > "$PROJECT_DIR/settings.gradle"
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "AIVideoTranslatorLegacy"
include ':app'
EOF

# 4. build.gradle (Root)
cat << 'EOF' > "$PROJECT_DIR/build.gradle"
plugins {
    id 'com.android.application' version '8.1.4' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.10' apply false
}
EOF

# 5. gradle.properties
cat << 'EOF' > "$PROJECT_DIR/gradle.properties"
org.gradle.jvmargs=-Xmx3072m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF

# 6. app/build.gradle
cat << 'EOF' > "$PROJECT_DIR/app/build.gradle"
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

def geminiApiKey = System.getenv("GEMINI_API_KEY") ?: ""

android {
    namespace 'com.example.videotranslator'
    compileSdk 33

    defaultConfig {
        applicationId "com.example.videotranslator"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"

        buildConfigField "String", "GEMINI_API_KEY", "\"${geminiApiKey}\""

        ndk {
            abiFilters "arm64-v8a", "armeabi-v7a"
        }
    }

    buildFeatures {
        buildConfig true
    }

    signingConfigs {
        debug {
            enableV1Signing true
            enableV2Signing true
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.debug
        }
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    packagingOptions {
        resources {
            excludes += ['/META-INF/{AL2.0,LGPL2.1}']
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.10.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'

    // FFmpeg Kit untuk pemrosesan video & subtitle
    implementation 'com.arthenica:ffmpeg-kit-full:6.0-2'

    // OkHttp & JSON untuk Gemini File API
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    implementation 'org.json:json:20230618'
}
EOF

# 7. AndroidManifest.xml
cat << 'EOF' > "$PROJECT_DIR/app/src/main/AndroidManifest.xml"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />

    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:requestLegacyExternalStorage="true"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# 8. strings.xml
cat << 'EOF' > "$RES_VALUES_PATH/strings.xml"
<resources>
    <string name="app_name">AI Video Translator</string>
</resources>
EOF

# 9. activity_main.xml
cat << 'EOF' > "$RES_LAYOUT_PATH/activity_main.xml"
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="16dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="AI Video Translator (Legacy Edition)"
            android:textSize="20sp"
            android:textStyle="bold"
            android:gravity="center"
            android:layout_marginBottom="16dp" />

        <EditText
            android:id="@+id/etApiKey"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:hint="Masukkan Gemini API Key (AIzaSy...)"
            android:inputType="textPassword"
            android:layout_marginBottom="12dp" />

        <Button
            android:id="@+id/btnPickVideo"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Pilih Video dari Galeri"
            android:layout_marginBottom="12dp" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Pilih Bahasa Tujuan:"
            android:textStyle="bold" />

        <Spinner
            android:id="@+id/spinnerLanguage"
            android:layout_width="match_parent"
            android:layout_height="48dp"
            android:layout_marginBottom="12dp" />

        <Switch
            android:id="@+id/switchDubbing"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Aktifkan Dubbing Suara AI (TTS)"
            android:layout_marginBottom="16dp" />

        <Button
            android:id="@+id/btnProcess"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Mulai Terjemahkan Video"
            android:enabled="false"
            android:layout_marginBottom="16dp" />

        <ProgressBar
            android:id="@+id/progressBar"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="center"
            android:visibility="gone"
            android:layout_marginBottom="8dp" />

        <TextView
            android:id="@+id/tvStatus"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Siap memproses video."
            android:gravity="center"
            android:layout_marginBottom="16dp" />

        <VideoView
            android:id="@+id/videoView"
            android:layout_width="match_parent"
            android:layout_height="240dp"
            android:visibility="gone"
            android:layout_marginBottom="12dp" />

        <Button
            android:id="@+id/btnSaveGallery"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Simpan Video ke Galeri"
            android:visibility="gone" />

    </LinearLayout>
</ScrollView>
EOF

# 10. VideoProcessor.kt
cat << 'EOF' > "$PKG_PATH/VideoProcessor.kt"
package com.example.videotranslator

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.util.Locale
import kotlin.coroutines.resume

class VideoProcessor(private val context: Context) {

    suspend fun copyUriToCache(uri: Uri): File? = withContext(Dispatchers.IO) {
        try {
            val inputStream = context.contentResolver.openInputStream(uri) ?: return@withContext null
            val tempFile = File(context.cacheDir, "input_${System.currentTimeMillis()}.mp4")
            FileOutputStream(tempFile).use { output -> inputStream.copyTo(output) }
            tempFile
        } catch (e: Exception) {
            null
        }
    }

    suspend fun extractAudio(videoPath: String, outputAudioPath: String): Boolean = withContext(Dispatchers.IO) {
        val command = "-i \"$videoPath\" -vn -acodec libmp3lame -q:a 4 \"$outputAudioPath\" -y"
        ReturnCode.isSuccess(FFmpegKit.execute(command).returnCode)
    }

    suspend fun generateDubbingAudio(srtContent: String, languageName: String, outputWavFile: File): Boolean =
        suspendCancellableCoroutine { continuation ->
            val cleanText = srtContent.lines()
                .filter { !it.matches(Regex("^\\d+$")) && !it.contains("-->") && it.isNotBlank() }
                .joinToString(". ")

            var tts: TextToSpeech? = null
            tts = TextToSpeech(context) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    val locale = when (languageName) {
                        "Bahasa Indonesia" -> Locale("id", "ID")
                        "Bahasa Inggris" -> Locale.US
                        "Bahasa Jepang" -> Locale.JAPAN
                        "Bahasa Korea" -> Locale.KOREA
                        "Bahasa Arab" -> Locale("ar")
                        else -> Locale("id", "ID")
                    }
                    tts?.language = locale
                    tts?.setSpeechRate(1.1f)

                    tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {}
                        override fun onDone(utteranceId: String?) {
                            tts?.shutdown()
                            if (continuation.isActive) continuation.resume(true)
                        }
                        override fun onError(utteranceId: String?) {
                            tts?.shutdown()
                            if (continuation.isActive) continuation.resume(false)
                        }
                    })

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        tts?.synthesizeToFile(cleanText, null, outputWavFile, "dubbing_id")
                    } else {
                        @Suppress("DEPRECATION")
                        val params = HashMap<String, String>()
                        params[TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID] = "dubbing_id"
                        @Suppress("DEPRECATION")
                        tts?.synthesizeToFile(cleanText, params, outputWavFile.absolutePath)
                    }
                } else {
                    if (continuation.isActive) continuation.resume(false)
                }
            }
        }

    suspend fun renderFinalVideo(
        videoPath: String,
        srtPath: String,
        dubbingAudioPath: String?,
        outputVideoPath: String
    ): Boolean = withContext(Dispatchers.IO) {
        val subFilter = "subtitles='$srtPath':force_style='FontSize=20,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=2'"
        
        val command = if (dubbingAudioPath != null) {
            "-i \"$videoPath\" -i \"$dubbingAudioPath\" -vf \"$subFilter\" -map 0:v:0 -map 1:a:0 -c:v libx264 -preset ultrafast -c:a aac -shortest \"$outputVideoPath\" -y"
        } else {
            "-i \"$videoPath\" -vf \"$subFilter\" -c:a copy \"$outputVideoPath\" -y"
        }
        ReturnCode.isSuccess(FFmpegKit.execute(command).returnCode)
    }

    suspend fun saveVideoToGallery(videoFile: File): Boolean = withContext(Dispatchers.IO) {
        try {
            val filename = "Translated_${System.currentTimeMillis()}.mp4"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Video.Media.DISPLAY_NAME, filename)
                    put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                    put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/VideoTranslator")
                    put(MediaStore.Video.Media.IS_PENDING, 1)
                }

                val resolver = context.contentResolver
                val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values) ?: return@withContext false

                resolver.openOutputStream(uri)?.use { outputStream ->
                    videoFile.inputStream().use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }

                values.clear()
                values.put(MediaStore.Video.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                true
            } else {
                val moviesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
                val appDir = File(moviesDir, "VideoTranslator")
                if (!appDir.exists()) appDir.mkdirs()

                val destFile = File(appDir, filename)
                videoFile.copyTo(destFile, overwrite = true)

                MediaScannerConnection.scanFile(context, arrayOf(destFile.absolutePath), arrayOf("video/mp4"), null)
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
EOF

# 11. GeminiTranslatorService.kt
cat << 'EOF' > "$PKG_PATH/GeminiTranslatorService.kt"
package com.example.videotranslator

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

class GeminiTranslatorService(private val apiKey: String) {

    private val client = OkHttpClient.Builder()
        .connectTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(120, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .build()

    suspend fun translateLongAudioToSrt(audioFile: File, targetLanguage: String): String = withContext(Dispatchers.IO) {
        val effectiveApiKey = apiKey.trim().ifEmpty { BuildConfig.GEMINI_API_KEY.trim() }
        if (effectiveApiKey.isBlank()) {
            throw Exception("Harap masukkan Gemini API Key terlebih dahulu.")
        }

        val fileUri = uploadToGeminiFileApi(audioFile, effectiveApiKey)
            ?: throw Exception("Gagal mengunggah audio ke server AI.")

        val prompt = """
            Dengarkan seluruh isi audio ini. Transkripsikan dan terjemahkan ke dalam bahasa $targetLanguage.
            Keluarkan hasil HANYA dalam format subtitle SubRip (.srt) yang valid lengkap dengan nomor urut dan timestamp (contoh: 00:00:01,000 --> 00:00:04,000).
            JANGAN tambahkan teks pembuka, penutup, atau blok markdown (```srt). Langsung mulai dengan angka 1.
        """.trimIndent()

        val requestJson = JSONObject().apply {
            put("contents", JSONArray().apply {
                put(JSONObject().apply {
                    put("parts", JSONArray().apply {
                        put(JSONObject().apply {
                            put("file_data", JSONObject().apply {
                                put("mime_type", "audio/mp3")
                                put("file_uri", fileUri)
                            })
                        })
                        put(JSONObject().apply {
                            put("text", prompt)
                        })
                    })
                })
            })
        }

        val request = Request.Builder()
            .url("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$effectiveApiKey")
            .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: throw Exception("Respon kosong dari AI.")
            if (!response.isSuccessful) throw Exception("API Error: $responseBody")

            val json = JSONObject(responseBody)
            val text = json.getJSONArray("candidates")
                .getJSONObject(0)
                .getJSONObject("content")
                .getJSONArray("parts")
                .getJSONObject(0)
                .getString("text")

            return@withContext text.replace("```srt", "").replace("```", "").trim()
        }
    }

    private fun uploadToGeminiFileApi(file: File, activeKey: String): String? {
        val fileSize = file.length()
        val initJson = JSONObject().apply {
            put("file", JSONObject().apply { put("display_name", file.name) })
        }

        val initRequest = Request.Builder()
            .url("https://generativelanguage.googleapis.com/upload/v1beta/files?key=$activeKey")
            .addHeader("X-Goog-Upload-Protocol", "resumable")
            .addHeader("X-Goog-Upload-Command", "start")
            .addHeader("X-Goog-Upload-Header-Content-Length", fileSize.toString())
            .addHeader("X-Goog-Upload-Header-Content-Type", "audio/mp3")
            .post(initJson.toString().toRequestBody("application/json".toMediaType()))
            .build()

        val uploadUrl = client.newCall(initRequest).execute().use { resp ->
            resp.header("X-Goog-Upload-URL")
        } ?: return null

        val uploadRequest = Request.Builder()
            .url(uploadUrl)
            .addHeader("Content-Length", fileSize.toString())
            .addHeader("X-Goog-Upload-Offset", "0")
            .addHeader("X-Goog-Upload-Command", "upload, finalize")
            .post(file.asRequestBody("audio/mp3".toMediaType()))
            .build()

        return client.newCall(uploadRequest).execute().use { resp ->
            val body = resp.body?.string() ?: return null
            JSONObject(body).getJSONObject("file").getString("uri")
        }
    }
}
EOF

# 12. MainActivity.kt
cat << 'EOF' > "$PKG_PATH/MainActivity.kt"
package com.example.videotranslator

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*
import java.io.File

class MainActivity : AppCompatActivity() {

    private lateinit var etApiKey: EditText
    private lateinit var btnPickVideo: Button
    private lateinit var spinnerLanguage: Spinner
    private lateinit var switchDubbing: Switch
    private lateinit var btnProcess: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var tvStatus: TextView
    private lateinit var videoView: VideoView
    private lateinit var btnSaveGallery: Button

    private var selectedVideoUri: Uri? = null
    private var finalOutputFile: File? = null
    private lateinit var videoProcessor: VideoProcessor
    private val mainScope = CoroutineScope(Dispatchers.Main + Job())

    private val PICK_VIDEO_REQUEST = 1001
    private val PERMISSION_REQUEST = 1002

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        videoProcessor = VideoProcessor(this)

        etApiKey = findViewById(R.id.etApiKey)
        btnPickVideo = findViewById(R.id.btnPickVideo)
        spinnerLanguage = findViewById(R.id.spinnerLanguage)
        switchDubbing = findViewById(R.id.switchDubbing)
        btnProcess = findViewById(R.id.btnProcess)
        progressBar = findViewById(R.id.progressBar)
        tvStatus = findViewById(R.id.tvStatus)
        videoView = findViewById(R.id.videoView)
        btnSaveGallery = findViewById(R.id.btnSaveGallery)

        if (BuildConfig.GEMINI_API_KEY.isNotBlank()) {
            etApiKey.setText(BuildConfig.GEMINI_API_KEY)
        }

        val languages = arrayOf("Bahasa Indonesia", "Bahasa Inggris", "Bahasa Jepang", "Bahasa Korea", "Bahasa Arab")
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, languages)
        spinnerLanguage.adapter = adapter

        checkPermissions()

        btnPickVideo.setOnClickListener {
            val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "video/*"
            }
            startActivityForResult(Intent.createChooser(intent, "Pilih Video"), PICK_VIDEO_REQUEST)
        }

        btnProcess.setOnClickListener {
            val apiKey = etApiKey.text.toString().trim().ifEmpty { BuildConfig.GEMINI_API_KEY.trim() }
            val videoUri = selectedVideoUri
            if (apiKey.isEmpty()) {
                Toast.makeText(this, "Masukkan Gemini API Key dulu!", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            if (videoUri != null) {
                startTranslationProcess(apiKey, videoUri, spinnerLanguage.selectedItem.toString(), switchDubbing.isChecked)
            }
        }

        btnSaveGallery.setOnClickListener {
            finalOutputFile?.let { file ->
                mainScope.launch {
                    btnSaveGallery.isEnabled = false
                    val saved = videoProcessor.saveVideoToGallery(file)
                    if (saved) {
                        Toast.makeText(this@MainActivity, "Berhasil disimpan ke folder Movies/VideoTranslator!", Toast.LENGTH_LONG).show()
                        btnSaveGallery.text = "Tersimpan di Galeri ✓"
                    } else {
                        Toast.makeText(this@MainActivity, "Gagal menyimpan video.", Toast.LENGTH_SHORT).show()
                        btnSaveGallery.isEnabled = true
                    }
                }
            }
        }
    }

    private fun checkPermissions() {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_VIDEO) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.READ_MEDIA_VIDEO)
            }
        } else {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                    permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                }
            }
        }
        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), PERMISSION_REQUEST)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_VIDEO_REQUEST && resultCode == RESULT_OK && data?.data != null) {
            selectedVideoUri = data.data
            btnPickVideo.text = "Video Terpilih (Ganti Video)"
            btnProcess.isEnabled = true
            tvStatus.text = "Video siap diproses."
        }
    }

    private fun startTranslationProcess(apiKey: String, videoUri: Uri, targetLang: String, enableDubbing: Boolean) {
        mainScope.launch {
            btnProcess.isEnabled = false
            btnPickVideo.isEnabled = false
            progressBar.visibility = View.VISIBLE
            videoView.visibility = View.GONE
            btnSaveGallery.visibility = View.GONE

            try {
                val aiService = GeminiTranslatorService(apiKey)

                tvStatus.text = "Menyiapkan file video..."
                val inputVideo = videoProcessor.copyUriToCache(videoUri)
                    ?: throw Exception("Gagal membaca file video.")

                tvStatus.text = "Mengekstrak audio..."
                val audioFile = File(cacheDir, "extracted_audio.mp3")
                if (!videoProcessor.extractAudio(inputVideo.absolutePath, audioFile.absolutePath)) {
                    throw Exception("Gagal mengekstrak audio.")
                }

                tvStatus.text = "Mengunggah & menerjemahkan dengan AI..."
                val srtContent = aiService.translateLongAudioToSrt(audioFile, targetLang)
                if (srtContent.isBlank()) throw Exception("AI gagal menghasilkan terjemahan.")

                val srtFile = File(cacheDir, "subtitle.srt")
                srtFile.writeText(srtContent)

                var dubbingFile: File? = null
                if (enableDubbing) {
                    tvStatus.text = "Membuat suara dubbing AI..."
                    val wavFile = File(cacheDir, "dubbing.wav")
                    if (videoProcessor.generateDubbingAudio(srtContent, targetLang, wavFile)) {
                        dubbingFile = wavFile
                    }
                }

                tvStatus.text = "Merender video akhir..."
                val outputVideo = File(cacheDir, "final_${System.currentTimeMillis()}.mp4")
                val isRendered = videoProcessor.renderFinalVideo(
                    videoPath = inputVideo.absolutePath,
                    srtPath = srtFile.absolutePath,
                    dubbingAudioPath = dubbingFile?.absolutePath,
                    outputVideoPath = outputVideo.absolutePath
                )

                if (!isRendered) throw Exception("Gagal merender video akhir.")

                finalOutputFile = outputVideo
                tvStatus.text = "Terjemahan Selesai!"

                val mediaController = MediaController(this@MainActivity)
                mediaController.setAnchorView(videoView)
                videoView.setMediaController(mediaController)
                videoView.setVideoURI(Uri.fromFile(outputVideo))
                videoView.visibility = View.VISIBLE
                videoView.start()

                btnSaveGallery.visibility = View.VISIBLE
                btnSaveGallery.isEnabled = true
                btnSaveGallery.text = "Simpan Video ke Galeri"

            } catch (e: Exception) {
                tvStatus.text = "Error: ${e.message}"
            } finally {
                progressBar.visibility = View.GONE
                btnProcess.isEnabled = true
                btnPickVideo.isEnabled = true
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mainScope.cancel()
    }
}
EOF

echo "Selesai! Folder proyek '$PROJECT_DIR' siap di-push ke GitHub."
