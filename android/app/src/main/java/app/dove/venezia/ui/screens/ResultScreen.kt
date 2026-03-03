package app.dove.venezia.ui.screens

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.net.Uri
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Navigation
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import app.dove.venezia.R
import app.dove.venezia.data.model.Sestiere
import app.dove.venezia.data.model.ZonaNormale
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.ui.theme.VeneziaPrimary
import app.dove.venezia.ui.theme.VeneziaPrimaryDark
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.location.LocationComponentActivationOptions
import org.maplibre.android.location.modes.CameraMode
import org.maplibre.android.location.modes.RenderMode
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style
import org.maplibre.android.style.expressions.Expression
import org.maplibre.android.style.layers.FillExtrusionLayer
import org.maplibre.android.style.layers.Property
import org.maplibre.android.style.layers.PropertyFactory
import kotlin.math.roundToInt

private const val OPENFREEMAP_STYLE      = "https://tiles.openfreemap.org/styles/positron"
private const val OPENFREEMAP_STYLE_DARK = "https://tiles.openfreemap.org/styles/dark"
private const val ZOOM_LEVEL        = 17.0
private const val TILT_3D           = 45.0
private const val TILT_2D           = 0.0

private fun formatDistance(meters: Float): String = when {
    meters < 1000f -> "%.0f m".format(meters)
    else           -> "%.1f km".format(meters / 1000f)
}

// ─── Screen ───────────────────────────────────────────────────────────────────

@Composable
fun ResultScreen(
    sestiereCode: String,
    numero: String,
    lat: Double,
    lng: Double,
    via: String? = null,
    onBack: () -> Unit
) {
    val context        = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val sestiere       = Sestiere.fromCode(sestiereCode)
    val zona           = if (sestiere == null) ZonaNormale.fromCode(sestiereCode) else null
    val displayName    = sestiere?.displayName ?: zona?.displayName ?: sestiereCode

    val isDark       = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val primaryColor = if (isDark) VeneziaPrimaryDark else VeneziaPrimary
    val mapStyleUrl  = if (isDark) OPENFREEMAP_STYLE_DARK else OPENFREEMAP_STYLE

    // Nizioleto card: sempre stile nizioleto (bianco/nero)
    val nizBg     = Color.White
    val nizBorder = Color(0xFF2A2A2A)
    val nizText   = Color(0xFF2A2A2A)

    // Pulsanti mappa: adattivi al tema
    val btnSurface  = if (isDark) Color.Black.copy(alpha = 0.45f) else Color.White.copy(alpha = 0.85f)
    val btnContent  = if (isDark) Color.White else Color(0xFF1A1A1A)

    // Vignette: adattiva al tema
    val vigColor = MaterialTheme.colorScheme.surface

    var is3D           by remember { mutableStateOf(true) }
    var styleReady     by remember { mutableStateOf(false) }
    var mapRef         by remember { mutableStateOf<MapLibreMap?>(null) }
    val setupInitiated = remember { java.util.concurrent.atomic.AtomicBoolean(false) }
    var distanceText   by remember { mutableStateOf<String?>(null) }

    // Posizione marker sullo schermo (pixel device) — guida l'overlay Compose
    var markerPx by remember { mutableStateOf<Pair<Float, Float>?>(null) }

    // Calcola distanza utente → civico
    LaunchedEffect(Unit) {
        if (ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            val lm = context.getSystemService(android.content.Context.LOCATION_SERVICE)
                as android.location.LocationManager
            val provider = if (lm.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER))
                android.location.LocationManager.GPS_PROVIDER
            else android.location.LocationManager.NETWORK_PROVIDER
            @SuppressLint("MissingPermission")
            val loc: Location? = lm.getLastKnownLocation(provider)
            if (loc != null) {
                val r = FloatArray(1)
                Location.distanceBetween(loc.latitude, loc.longitude, lat, lng, r)
                distanceText = formatDistance(r[0])
            }
        }
    }

    // Aggiorna posizione schermo del marker quando lo stile è pronto o la camera si muove
    LaunchedEffect(styleReady) {
        if (!styleReady) return@LaunchedEffect
        val map = mapRef ?: return@LaunchedEffect
        fun updatePos() {
            val pt = map.projection.toScreenLocation(LatLng(lat, lng))
            markerPx = Pair(pt.x, pt.y)
        }
        updatePos()
        map.addOnCameraMoveListener { updatePos() }
        map.addOnCameraIdleListener { updatePos() }
    }

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

        // ── Mappa ─────────────────────────────────────────────────────────────
        AndroidView(
            factory  = { mapView },
            modifier = Modifier.fillMaxSize(),
            update   = { mv ->
                if (setupInitiated.compareAndSet(false, true)) {
                    mv.getMapAsync { map ->
                        mapRef = map
                        map.setStyle(Style.Builder().fromUri(mapStyleUrl)) { style ->

                            // Layer edifici 3D
                            try {
                                val extrusionColor = if (isDark) "#3A3530" else "#C8C0B8"
                                style.addLayer(
                                    FillExtrusionLayer("3d-buildings", "openmaptiles").apply {
                                        setSourceLayer("building")
                                        setProperties(
                                            PropertyFactory.fillExtrusionColor(extrusionColor),
                                            PropertyFactory.fillExtrusionHeight(
                                                Expression.coalesce(
                                                    Expression.get("height"),
                                                    Expression.literal(6)
                                                )
                                            ),
                                            PropertyFactory.fillExtrusionBase(
                                                Expression.coalesce(
                                                    Expression.get("min_height"),
                                                    Expression.literal(0)
                                                )
                                            ),
                                            PropertyFactory.fillExtrusionOpacity(0.7f)
                                        )
                                    }
                                )
                            } catch (_: Exception) { }

                            // Posizione utente
                            if (ContextCompat.checkSelfPermission(
                                    context, Manifest.permission.ACCESS_FINE_LOCATION
                                ) == PackageManager.PERMISSION_GRANTED
                            ) {
                                @Suppress("MissingPermission")
                                map.locationComponent.let { lc ->
                                    lc.activateLocationComponent(
                                        LocationComponentActivationOptions
                                            .builder(context, style)
                                            .useDefaultLocationEngine(true)
                                            .build()
                                    )
                                    lc.isLocationComponentEnabled = true
                                    lc.cameraMode  = CameraMode.NONE
                                    lc.renderMode  = RenderMode.COMPASS
                                }
                            }

                            styleReady = true
                        }
                        map.cameraPosition = CameraPosition.Builder()
                            .target(LatLng(lat, lng))
                            .zoom(ZOOM_LEVEL)
                            .tilt(TILT_3D)
                            .build()
                    }
                }
            }
        )

        // ── Vignettatura adattiva al tema ──────────────────────────────────────
        Box(
            modifier = Modifier.fillMaxSize().background(
                Brush.verticalGradient(
                    0f    to vigColor.copy(alpha = 0.80f),
                    0.22f to vigColor.copy(alpha = 0.20f),
                    0.30f to Color.Transparent,
                    0.62f to Color.Transparent,
                    0.76f to vigColor.copy(alpha = 0.30f),
                    1f    to vigColor.copy(alpha = 0.90f)
                )
            )
        )

        // ── Marker overlay (sempre sopra gli edifici) ─────────────────────────
        markerPx?.let { (px, py) ->
            Column(
                modifier = Modifier
                    .layout { measurable, constraints ->
                        val placeable = measurable.measure(
                            constraints.copy(minWidth = 0, minHeight = 0)
                        )
                        layout(constraints.maxWidth, constraints.maxHeight) {
                            placeable.place(
                                x = px.roundToInt() - placeable.width / 2,
                                y = py.roundToInt() - placeable.height
                            )
                        }
                    },
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Bubble
                Box(
                    modifier = Modifier
                        .background(primaryColor, RoundedCornerShape(10.dp))
                        .padding(horizontal = 14.dp, vertical = 7.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text       = numero,
                            fontFamily = SotoportegoFontFamily,
                            fontSize   = 18.sp,
                            color      = Color.White,
                            fontWeight = FontWeight.Normal
                        )
                        distanceText?.let {
                            Text(
                                text  = it,
                                color = Color.White.copy(alpha = 0.85f),
                                fontSize = 10.sp,
                                modifier = Modifier.padding(top = 1.dp)
                            )
                        }
                    }
                }
                // Freccia
                val arrowColor = primaryColor
                Canvas(modifier = Modifier.size(width = 14.dp, height = 8.dp)) {
                    drawPath(
                        path = Path().apply {
                            moveTo(0f, 0f)
                            lineTo(size.width, 0f)
                            lineTo(size.width / 2f, size.height)
                            close()
                        },
                        color = arrowColor
                    )
                }
            }
        }

        // ── Nizioleto (top center) ─────────────────────────────────────────────
        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .statusBarsPadding()
                .padding(top = 8.dp)
                .background(nizBg, RoundedCornerShape(14.dp))
                .border(2.dp, nizBorder, RoundedCornerShape(14.dp))
                .padding(horizontal = 22.dp, vertical = 10.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text          = displayName.uppercase(),
                    fontFamily    = SotoportegoFontFamily,
                    fontSize      = 11.sp,
                    letterSpacing = 2.sp,
                    color         = nizText,
                    fontWeight    = FontWeight.Normal
                )
                if (via != null) {
                    Text(
                        text          = via.uppercase(),
                        fontFamily    = SotoportegoFontFamily,
                        fontSize      = 11.sp,
                        letterSpacing = 1.sp,
                        color         = nizText.copy(alpha = 0.6f),
                        fontWeight    = FontWeight.Normal
                    )
                }
                Text(
                    text       = numero,
                    fontFamily = SotoportegoFontFamily,
                    fontSize   = 40.sp,
                    color      = primaryColor,
                    fontWeight = FontWeight.Normal,
                    lineHeight = 44.sp
                )
            }
        }

        // ── Back (top left) ───────────────────────────────────────────────────
        MapCircleButton(
            surface  = btnSurface,
            modifier = Modifier
                .align(Alignment.TopStart)
                .statusBarsPadding()
                .padding(12.dp),
            onClick  = onBack
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, null, tint = btnContent,
                modifier = Modifier.size(20.dp))
        }

        // ── Share (top right) ─────────────────────────────────────────────────
        MapCircleButton(
            surface  = btnSurface,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .statusBarsPadding()
                .padding(12.dp),
            onClick  = {
                val shareText = "$displayName $numero\ngeo:$lat,$lng"
                context.startActivity(
                    Intent.createChooser(
                        Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, shareText)
                        }, null
                    )
                )
            }
        ) {
            Icon(Icons.Default.Share, null, tint = btnContent,
                modifier = Modifier.size(20.dp))
        }

        // ── Bottom: controlli mappa + pulsante Naviga ─────────────────────────
        Row(
            modifier              = Modifier
                .align(Alignment.BottomStart)
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(start = 16.dp, end = 16.dp, bottom = 24.dp),
            verticalAlignment     = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {

                // 2D / 3D toggle
                MapCircleButton(surface = btnSurface, onClick = {
                    val next = !is3D
                    is3D = next
                    mapRef?.animateCamera(
                        CameraUpdateFactory.newCameraPosition(
                            CameraPosition.Builder()
                                .target(LatLng(lat, lng)).zoom(ZOOM_LEVEL)
                                .tilt(if (next) TILT_3D else TILT_2D).build()
                        ), 600
                    )
                    mapRef?.getStyle { style ->
                        try {
                            style.getLayer("3d-buildings")?.setProperties(
                                PropertyFactory.visibility(
                                    if (next) Property.VISIBLE else Property.NONE
                                )
                            )
                        } catch (_: Exception) { }
                    }
                }) {
                    Text(if (is3D) "2D" else "3D", color = btnContent,
                        fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }

                // Centra sul civico
                MapCircleButton(surface = btnSurface, onClick = {
                    mapRef?.animateCamera(
                        CameraUpdateFactory.newCameraPosition(
                            CameraPosition.Builder()
                                .target(LatLng(lat, lng)).zoom(ZOOM_LEVEL)
                                .tilt(if (is3D) TILT_3D else TILT_2D).build()
                        ), 600
                    )
                }) {
                    Icon(Icons.Default.MyLocation, null, tint = btnContent,
                        modifier = Modifier.size(20.dp))
                }

                // Orienta verso nord
                MapCircleButton(surface = btnSurface, onClick = {
                    mapRef?.animateCamera(
                        CameraUpdateFactory.newCameraPosition(
                            CameraPosition.Builder()
                                .target(LatLng(lat, lng)).zoom(ZOOM_LEVEL)
                                .tilt(if (is3D) TILT_3D else TILT_2D)
                                .bearing(0.0).build()
                        ), 600
                    )
                }) {
                    Icon(Icons.Default.Explore, null, tint = btnContent,
                        modifier = Modifier.size(20.dp))
                }
            }

            // Pulsante Naviga
            Button(
                onClick = {
                    val uri = Uri.parse("geo:$lat,$lng?q=$lat,$lng($displayName $numero)")
                    context.startActivity(Intent(Intent.ACTION_VIEW, uri))
                },
                modifier = Modifier
                    .weight(1f)
                    .height(52.dp),
                shape  = RoundedCornerShape(28.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = primaryColor,
                    contentColor   = Color.White
                )
            ) {
                Icon(Icons.Default.Navigation, null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text(
                    text       = stringResource(R.string.naviga),
                    fontSize   = 16.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

// ─── Bottone cerchio riutilizzabile ───────────────────────────────────────────
@Composable
private fun MapCircleButton(
    surface:  Color,
    modifier: Modifier = Modifier,
    onClick:  () -> Unit,
    content:  @Composable () -> Unit
) {
    Surface(
        onClick  = onClick,
        shape    = CircleShape,
        color    = surface,
        modifier = modifier.size(44.dp)
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
            content()
        }
    }
}
