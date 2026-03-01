package app.dove.venezia.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import app.dove.venezia.R
import app.dove.venezia.data.model.Sestiere
import app.dove.venezia.data.model.ZonaNormale
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style

// Positron: stile minimalista, elegante, bianco/grigio chiaro
private const val OPENFREEMAP_STYLE = "https://tiles.openfreemap.org/styles/positron"

@Composable
fun ResultScreen(
    sestiereCode: String,
    numero: String,
    lat: Double,
    lng: Double,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val sestiere = Sestiere.fromCode(sestiereCode)
    val zona = if (sestiere == null) ZonaNormale.fromCode(sestiereCode) else null
    val displayName = sestiere?.displayName ?: zona?.displayName ?: sestiereCode
    val accentColor = sestiere?.color ?: zona?.color ?: MaterialTheme.colorScheme.primary

    MapLibre.getInstance(context)
    val mapView = remember { MapView(context) }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START   -> mapView.onStart()
                Lifecycle.Event.ON_RESUME  -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE   -> mapView.onPause()
                Lifecycle.Event.ON_STOP    -> mapView.onStop()
                Lifecycle.Event.ON_DESTROY -> mapView.onDestroy()
                else                       -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    Box(modifier = Modifier.fillMaxSize()) {

        // ── Mappa a tutto schermo ──────────────────────────────────────────
        AndroidView(
            factory = { mapView },
            modifier = Modifier.fillMaxSize(),
            update = { mv ->
                mv.getMapAsync { map ->
                    val position = LatLng(lat, lng)
                    map.setStyle(Style.Builder().fromUri(OPENFREEMAP_STYLE)) {
                        map.addMarker(
                            org.maplibre.android.annotations.MarkerOptions()
                                .position(position)
                                .title("$displayName $numero")
                        )
                    }
                    map.cameraPosition = CameraPosition.Builder()
                        .target(position)
                        .zoom(17.0)
                        .build()
                }
            }
        )

        // ── Vignettatura: sfumatura scura agli estremi, trasparente al centro ──
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0f    to Color.Black.copy(alpha = 0.45f),
                        0.28f to Color.Transparent,
                        0.72f to Color.Transparent,
                        1f    to Color.Black.copy(alpha = 0.55f)
                    )
                )
        )

        // ── TopBar trasparente sovrapposta ─────────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopStart)
                .statusBarsPadding()
                .padding(horizontal = 4.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.back),
                    tint = Color.White
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "$displayName $numero",
                    fontFamily = SotoportegoFontFamily,
                    fontWeight = FontWeight.Normal,
                    fontSize = 20.sp,
                    letterSpacing = 1.5.sp,
                    color = Color.White
                )
                Text(
                    text = "%.6f, %.6f".format(lat, lng),
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White.copy(alpha = 0.7f)
                )
            }
            IconButton(onClick = {
                val shareText = "$displayName $numero\ngeo:$lat,$lng"
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, shareText)
                }
                context.startActivity(Intent.createChooser(intent, null))
            }) {
                Icon(
                    Icons.Default.Share,
                    contentDescription = stringResource(R.string.share),
                    tint = Color.White
                )
            }
        }

        // ── BottomBar trasparente sovrapposta ──────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomStart)
                .navigationBarsPadding()
                .padding(horizontal = 16.dp, vertical = 20.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Google Maps
            Button(
                onClick = {
                    val uri = Uri.parse("geo:$lat,$lng?q=$lat,$lng($displayName $numero)")
                    val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                        setPackage("com.google.android.apps.maps")
                    }
                    if (intent.resolveActivity(context.packageManager) != null) {
                        context.startActivity(intent)
                    } else {
                        context.startActivity(Intent(Intent.ACTION_VIEW, uri))
                    }
                },
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White,
                    contentColor = Color.Black
                )
            ) {
                Text(stringResource(R.string.open_maps), fontWeight = FontWeight.Medium)
            }

            // Waze
            OutlinedButton(
                onClick = {
                    val uri = Uri.parse("waze://?ll=$lat,$lng&navigate=yes")
                    val intent = Intent(Intent.ACTION_VIEW, uri)
                    if (intent.resolveActivity(context.packageManager) != null) {
                        context.startActivity(intent)
                    } else {
                        context.startActivity(
                            Intent(Intent.ACTION_VIEW,
                                Uri.parse("https://waze.com/ul?ll=$lat,$lng&navigate=yes"))
                        )
                    }
                },
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = 0.7f))
            ) {
                Text(stringResource(R.string.open_waze), fontWeight = FontWeight.Medium)
            }
        }
    }
}
