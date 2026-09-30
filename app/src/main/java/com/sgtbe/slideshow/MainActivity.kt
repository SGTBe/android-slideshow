package com.sgtbe.slideshow

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.documentfile.provider.DocumentFile
import androidx.lifecycle.lifecycleScope
import com.sgtbe.slideshow.databinding.ActivityMainBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    private val handler = Handler(Looper.getMainLooper())
    private val imageUris = mutableListOf<Uri>()
    private var currentIndex = 0
    private var isPlaying = false
    private var displayTimeMs = 5000L
    private var slideshowRunnable: Runnable? = null
    private var imageLoadJob: Job? = null

    private val pickFolderLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocumentTree()
    ) { treeUri ->
        if (treeUri == null) {
            Toast.makeText(this, "No folder selected", Toast.LENGTH_SHORT).show()
            return@registerForActivityResult
        }

        contentResolver.takePersistableUriPermission(
            treeUri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        )

        val root = DocumentFile.fromTreeUri(this, treeUri)
        if (root == null) {
            Toast.makeText(this, "Unable to access selected folder", Toast.LENGTH_SHORT).show()
            return@registerForActivityResult
        }

        // Walking a large folder tree through the document provider is slow, so do it off the main thread.
        lifecycleScope.launch {
            val found = withContext(Dispatchers.IO) { readImageUris(root) }

            imageUris.clear()
            imageUris.addAll(found)

            if (imageUris.isEmpty()) {
                Toast.makeText(this@MainActivity, "No images found in that folder", Toast.LENGTH_SHORT).show()
                return@launch
            }

            currentIndex = 0
            showCurrentImage()
            if (!isPlaying) {
                startSlideshow()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupTransitionOptions()
        setupDisplayTimeControl()
        setupButtons()

        binding.imageView.setBackgroundColor(getColor(android.R.color.black))
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSlideshow()
    }

    private fun setupTransitionOptions() {
        val transitions = listOf("Fade", "Slide", "Zoom", "None")
        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_item,
            transitions
        ).also {
            it.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        }

        binding.transitionSpinner.adapter = adapter
        binding.transitionSpinner.setSelection(0)
    }

    private fun setupDisplayTimeControl() {
        binding.displayTimeSeekBar.max = 14
        binding.displayTimeSeekBar.progress = 4
        updateDisplayTimeText()

        binding.displayTimeSeekBar.setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: android.widget.SeekBar?, progress: Int, fromUser: Boolean) {
                displayTimeMs = (progress + 1L) * 1000L
                updateDisplayTimeText()
                if (isPlaying) {
                    restartSlideshowTimer()
                }
            }

            override fun onStartTrackingTouch(seekBar: android.widget.SeekBar?) = Unit
            override fun onStopTrackingTouch(seekBar: android.widget.SeekBar?) = Unit
        })
    }

    private fun updateDisplayTimeText() {
        val seconds = (displayTimeMs / 1000L).toInt()
        binding.displayTimeValue.text = "$seconds seconds"
    }

    private fun setupButtons() {
        binding.chooseFolderButton.setOnClickListener {
            pickFolderLauncher.launch(null)
        }

        binding.playPauseButton.setOnClickListener {
            if (isPlaying) {
                pauseSlideshow()
            } else {
                if (imageUris.isNotEmpty()) {
                    startSlideshow()
                } else {
                    Toast.makeText(this, "Choose a folder first", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun startSlideshow() {
        if (imageUris.isEmpty()) {
            Toast.makeText(this, "No images to play", Toast.LENGTH_SHORT).show()
            return
        }

        isPlaying = true
        binding.playPauseButton.text = "Pause"
        scheduleNextImage()
    }

    private fun pauseSlideshow() {
        isPlaying = false
        binding.playPauseButton.text = "Play"
        slideshowRunnable?.let { handler.removeCallbacks(it) }
    }

    private fun stopSlideshow() {
        pauseSlideshow()
    }

    private fun restartSlideshowTimer() {
        if (!isPlaying) return
        slideshowRunnable?.let { handler.removeCallbacks(it) }
        scheduleNextImage()
    }

    private fun scheduleNextImage() {
        slideshowRunnable = Runnable {
            currentIndex = if (currentIndex + 1 >= imageUris.size) 0 else currentIndex + 1
            showCurrentImage()
            scheduleNextImage()
        }
        handler.postDelayed(slideshowRunnable!!, displayTimeMs)
    }

    private fun showCurrentImage() {
        if (imageUris.isEmpty()) {
            return
        }

        val uri = imageUris[currentIndex]
        val width = binding.imageView.width.takeIf { it > 0 } ?: resources.displayMetrics.widthPixels
        val height = binding.imageView.height.takeIf { it > 0 } ?: resources.displayMetrics.heightPixels

        // Decode on a background thread so large photos don't freeze the UI, then animate on the main thread.
        imageLoadJob?.cancel()
        imageLoadJob = lifecycleScope.launch {
            val bitmap = withContext(Dispatchers.IO) { decodeBitmapFromUri(uri, width, height) }
            if (bitmap == null) {
                Log.w(TAG, "Could not decode image: $uri")
                return@launch
            }
            animateImageChange(bitmap)
        }
    }

    private fun animateImageChange(bitmap: Bitmap) {
        binding.imageView.animate().cancel()
        when (binding.transitionSpinner.selectedItem?.toString()) {
            "Fade" -> fadeTo(bitmap)
            "Slide" -> slideTo(bitmap)
            "Zoom" -> zoomTo(bitmap)
            else -> setImage(bitmap)
        }
    }

    private fun fadeTo(bitmap: Bitmap) {
        binding.imageView.animate()
            .alpha(0f)
            .setDuration(200)
            .withEndAction {
                setImage(bitmap)
                binding.imageView.alpha = 1f
            }
            .start()
    }

    private fun slideTo(bitmap: Bitmap) {
        val width = binding.imageView.width.toFloat().takeIf { it > 0f } ?: 800f
        binding.imageView.animate()
            .translationX(-width)
            .alpha(0f)
            .setDuration(220)
            .withEndAction {
                setImage(bitmap)
                binding.imageView.translationX = width
                binding.imageView.alpha = 1f
                binding.imageView.animate()
                    .translationX(0f)
                    .alpha(1f)
                    .setDuration(220)
                    .start()
            }
            .start()
    }

    private fun zoomTo(bitmap: Bitmap) {
        binding.imageView.animate()
            .scaleX(0.8f)
            .scaleY(0.8f)
            .alpha(0.5f)
            .setDuration(220)
            .withEndAction {
                setImage(bitmap)
                binding.imageView.scaleX = 0.8f
                binding.imageView.scaleY = 0.8f
                binding.imageView.alpha = 0.5f
                binding.imageView.animate()
                    .scaleX(1f)
                    .scaleY(1f)
                    .alpha(1f)
                    .setDuration(220)
                    .start()
            }
            .start()
    }

    private fun setImage(bitmap: Bitmap) {
        binding.imageView.setImageBitmap(bitmap)
        binding.imageView.alpha = 1f
        binding.imageView.translationX = 0f
        binding.imageView.scaleX = 1f
        binding.imageView.scaleY = 1f
    }

    // Reads the image size first, then decodes a downsampled copy close to the view size.
    private fun decodeBitmapFromUri(uri: Uri, width: Int, height: Int): Bitmap? = try {
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }

        contentResolver.openInputStream(uri)?.use { inputStream ->
            BitmapFactory.decodeStream(inputStream, null, options)
        }

        val sampleSize = calculateInSampleSize(options, width, height)

        contentResolver.openInputStream(uri)?.use { inputStream ->
            BitmapFactory.Options().apply {
                inJustDecodeBounds = false
                inSampleSize = sampleSize
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }.let { bitmapOptions ->
                BitmapFactory.decodeStream(inputStream, null, bitmapOptions)
            }
        }
    } catch (e: Exception) {
        Log.w(TAG, "Failed to load image: $uri", e)
        null
    } catch (e: OutOfMemoryError) {
        Log.w(TAG, "Out of memory loading image: $uri", e)
        null
    }

    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2

            while ((halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }

    private fun readImageUris(root: DocumentFile): List<Uri> {
        val results = mutableListOf<Uri>()
        val imageExtensions = setOf(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp")

        fun traverse(folder: DocumentFile) {
            folder.listFiles().forEach { child ->
                if (child.isDirectory) {
                    traverse(child)
                    return@forEach
                }

                val name = child.name.orEmpty().lowercase()
                if (child.isFile && imageExtensions.any { name.endsWith(it) }) {
                    results.add(child.uri)
                }
            }
        }

        traverse(root)
        return results.sortedBy { it.lastPathSegment.orEmpty().lowercase() }
    }

    companion object {
        private const val TAG = "MainActivity"
    }
}
