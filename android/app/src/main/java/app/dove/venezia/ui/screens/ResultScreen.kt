package app.dove.venezia.ui.screens

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.location.Location
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
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
import com.google.gson.JsonObject
import com.google.gson.JsonArray
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
import org.maplibre.android.style.layers.SymbolLayer
import org.maplibre.android.style.sources.GeoJsonSource

// ─── Stili mappa ─────────────────────────────────────────────────────────────
// Light: OpenFreeMap Liberty (dettagliato, colori caldi)
// Dark: CartoDB Dark Matter (scuro ma leggibile, ottimo contrasto label)
private const val OPENFREEMAP_STYLE      = "https://tiles.openfreemap.org/styles/liberty"
private const val OPENFREEMAP_STYLE_DARK = "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
private const val ZOOM_LEVEL        = 17.0
private const val TILT_3D           = 45.0
private const val TILT_2D           = 0.0

// Source & layer IDs per il marker (SymbolLayer sopra gli edifici 3D)
private const val MARKER_SOURCE_ID = "marker-source"
private const val MARKER_LAYER_ID  = "marker-layer"
private const val MARKER_ICON_ID   = "marker-icon"

// ─── Marker bitmap ────────────────────────────────────────────────────────────

private fun buildMarkerBitmap(
    numero: String,
    distanceText: String?,
    accentArgb: Int
): Bitmap {
    val density      = 3f
    val cornerRadius = 12f * density
    val paddingH     = 16f * density
    val paddingV     = 10f * density
    val arrowHeight  = 10f * density
    val arrowWidth   = 14f * density

    val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color    = android.graphics.Color.WHITE
        typeface = Typeface.DEFAULT_BOLD
        textSize = 15f * density
    }
    val subPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color    = android.graphics.Color.WHITE
        typeface = Typeface.DEFAULT
        textSize = 10f * density
        alpha    = 220
    }

    val textW  = textPaint.measureText(numero)
    val subW   = if (distanceText != null) subPaint.measureText(distanceText) else 0f
    val bodyW  = maxOf(textW, subW) + paddingH * 2
    val bodyH  = if (distanceText != null)
        paddingV + textPaint.textSize + 4f * density + subPaint.textSize + paddingV
    else
        paddingV + textPaint.textSize + paddingV
    val totalH = bodyH + arrowHeight

    val bmp     = Bitmap.createBitmap(bodyW.toInt(), totalH.toInt(), Bitmap.Config.ARGB_8888)
    val canvas  = Canvas(bmp)
    val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = accentArgb }

    canvas.drawRoundRect(RectF(0f, 0f, bodyW, bodyH), cornerRadius, cornerRadius, bgPaint)
    val arrowPath = Path().apply {
        moveTo(bodyW / 2f - arrowWidth / 2f, bodyH)
        lineTo(bodyW / 2f + arrowWidth / 2f, bodyH)
        lineTo(bodyW / 2f, totalH)
        close()
    }
    canvas.drawPath(arrowPath, bgPaint)
    canvas.drawText(numero, (bodyW - textW) / 2f, paddingV + textPaint.textSize, textPaint)
    if (distanceText != null) {
        val subY = paddingV + textPaint.textSize + 4f * density + subPaint.textSize
        canvas.drawText(distanceText, (bodyW - subW) / 2f, subY, subPaint)
    }
    return bmp
}

private fun formatDistance(meters: Float): String = when {
    meters < 1000f -> "%.0f m".format(meters)
    else           -> "%.1f km".format(meters / 1000f)
}

/** Costruisce un GeoJSON Point per il marker */
private fun buildGeoJsonPoint(lat: Double, lng: Double): String {
    val geometry = JsonObject().apply {
        addProperty("type", "Point")
        add("coordinates", JsonArray().apply {
            add(lng)
            add(lat)
        })
    }
    return JsonObject().apply {
        addProperty("type", "Feature")
        add("geometry", geometry)
        add("properties", JsonObject())
    }.toString()
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

    // Dark mode: stile mappa adattivo, marker corallo corretto
    val isDark       = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val primaryColor = if (isDark) VeneziaPrimaryDark else VeneziaPrimary
    val mapStyleUrl  = if (isDark) OPENFREEMAP_STYLE_DARK else OPENFREEMAP_STYLE
    val markerArgb   = primaryColor.toArgb()

    // ── Colori pulsanti: bianco in light, scuro traslucido in dark ──────────
    val btnBg   = if (isDark) Color.Black.copy(alpha = 0.50f) else Color.White.copy(alpha = 0.92f)
    val btnTint = if (isDark) Color.White else Color(0xFF333333)

    // Nizioleto: adattivo — sfondo chiaro in light, scuro in dark (come iOS)
    val nizBg     = if (isDark) Color(0xFF2A2520) else Color.White
    val nizBorder = if (isDark) Color(0xFF8A8078) else Color(0xFF2A2A2A)
    val nizText   = if (isDark) Color(0xFFF0EBE0) else Color(0xFF2A2A2A)

    var is3D           by remember { mutableStateOf(true) }
    var styleReady     by remember { mutableStateOf(false) }
    var mapRef         by remember { mutableStateOf<MapLibreMap?>(null) }
    val setupInitiated = remember { java.util.concurrent.atomic.AtomicBoolean(false) }
    var distanceText      by remember { mutableStateOf<String?>(null) }
    var locationGranted   by remember { mutableStateOf(
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    ) }

    // Richiesta permesso location a runtime
    val locationLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        locationGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true ||
                          permissions[Manifest.permission.ACCESS_COARSE_LOCATION] == true
    }

    // Chiedi permesso al primo avvio se non ancora concesso
    LaunchedEffect(Unit) {
        if (!locationGranted) {
            locationLauncher.launch(arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ))
        }
    }

    // Calcola distanza utente → civico (ri-eseguito quando il permesso viene concesso)
    LaunchedEffect(locationGranted) {
        if (!locationGranted) return@LaunchedEffect
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

    // (Re)aggiunge marker via SymbolLayer (sopra gli edifici 3D)
    LaunchedEffect(styleReady, distanceText) {
        if (!styleReady) return@LaunchedEffect
        val map = mapRef ?: return@LaunchedEffect
        map.getStyle { style ->
            val bmp = buildMarkerBitmap(numero, distanceText, markerArgb)
            style.addImage(MARKER_ICON_ID, bmp)

            // Rimuovi layer/source precedente se esistono (aggiornamento distanza)
            style.getLayer(MARKER_LAYER_ID)?.let { style.removeLayer(it) }
            style.getSource(MARKER_SOURCE_ID)?.let { style.removeSource(it) }

            // Aggiunge source GeoJSON + SymbolLayer (renderizzato sopra tutto)
            style.addSource(GeoJsonSource(MARKER_SOURCE_ID, buildGeoJsonPoint(lat, lng)))
            style.addLayer(
                SymbolLayer(MARKER_LAYER_ID, MARKER_SOURCE_ID).apply {
                    setProperties(
                        PropertyFactory.iconImage(MARKER_ICON_ID),
                        PropertyFactory.iconAllowOverlap(true),
                        PropertyFactory.iconIgnorePlacement(true),
                        PropertyFactory.iconAnchor(Property.ICON_ANCHOR_BOTTOM),
                        PropertyFactory.iconOffset(arrayOf(0f, 0f))
                    )
                }
            )
        }
    }

    // Attiva location sulla mappa quando il permesso viene concesso dopo il setup
    LaunchedEffect(locationGranted, styleReady) {
        if (!locationGranted || !styleReady) return@LaunchedEffect
        val map = mapRef ?: return@LaunchedEffect
        map.getStyle { style ->
            if (!map.locationComponent.isLocationComponentActivated) {
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
        }
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

                            // Layer edifici 3D — colori più caldi come iOS
                            // OpenFreeMap usa "openmaptiles", CartoDB usa "carto"
                            try {
                                val extrusionColor = if (isDark) "#3A3530" else "#DDD5CC"
                                val extrusionOpacity = if (isDark) 0.8f else 0.75f
                                val vectorSourceId = if (isDark) "carto" else "openmaptiles"
                                style.addLayer(
                                    FillExtrusionLayer("3d-buildings", vectorSourceId).apply {
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
                                            PropertyFactory.fillExtrusionOpacity(extrusionOpacity)
                                        )
                                    }
                                )
                            } catch (_: Exception) { /* source non disponibile */ }

                            // Posizione utente (attivata solo se permesso concesso)
                            if (locationGranted) {
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

        // ── Vignettatura radiale adattiva (come iOS) ────────────────────────
        val vignetteColor = if (isDark) Color.Black else Color.White
        val vignetteAlpha = if (isDark) 0.40f else 0.50f
        Box(
            modifier = Modifier
                .fillMaxSize()
                .drawBehind {
                    drawRect(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                Color.Transparent,
                                vignetteColor.copy(alpha = vignetteAlpha * 0.6f),
                                vignetteColor.copy(alpha = vignetteAlpha)
                            ),
                            center = Offset(size.width / 2f, size.height / 2f),
                            radius = size.maxDimension / 1.6f
                        ),
                        size = size
                    )
                }
        )

        // ── Nizioleto (top center) ──────────────────────────────────────────
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

        // ── Back (top left) ─────────────────────────────────────────────────
        MapCircleButton(
            modifier = Modifier
                .align(Alignment.TopStart)
                .statusBarsPadding()
                .padding(12.dp),
            backgroundColor = btnBg,
            onClick  = onBack
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, null, tint = btnTint,
                modifier = Modifier.size(20.dp))
        }

        // ── Share (top right) ───────────────────────────────────────────────
        MapCircleButton(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .statusBarsPadding()
                .padding(12.dp),
            backgroundColor = btnBg,
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
            Icon(Icons.Default.Share, null, tint = btnTint,
                modifier = Modifier.size(20.dp))
        }

        // ── Bottom: controlli mappa (sinistra) + pulsante Naviga ────────────
        Row(
            modifier              = Modifier
                .align(Alignment.BottomStart)
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(start = 16.dp, end = 16.dp, bottom = 24.dp),
            verticalAlignment     = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Colonna sinistra: controlli mappa
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {

                // 2D / 3D toggle
                MapCircleButton(backgroundColor = btnBg, onClick = {
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
                    Text(if (is3D) "2D" else "3D", color = btnTint,
                        fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }

                // Centra sul civico
                MapCircleButton(backgroundColor = btnBg, onClick = {
                    mapRef?.animateCamera(
                        CameraUpdateFactory.newCameraPosition(
                            CameraPosition.Builder()
                                .target(LatLng(lat, lng)).zoom(ZOOM_LEVEL)
                                .tilt(if (is3D) TILT_3D else TILT_2D).build()
                        ), 600
                    )
                }) {
                    Icon(Icons.Default.MyLocation, null, tint = btnTint,
                        modifier = Modifier.size(20.dp))
                }

                // Orienta verso nord
                MapCircleButton(backgroundColor = btnBg, onClick = {
                    mapRef?.animateCamera(
                        CameraUpdateFactory.newCameraPosition(
                            CameraPosition.Builder()
                                .target(LatLng(lat, lng)).zoom(ZOOM_LEVEL)
                                .tilt(if (is3D) TILT_3D else TILT_2D)
                                .bearing(0.0).build()
                        ), 600
                    )
                }) {
                    Icon(Icons.Default.Explore, null, tint = btnTint,
                        modifier = Modifier.size(20.dp))
                }
            }

            // Pulsante Naviga — adattivo light/dark
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
                    containerColor = if (isDark) Color(0xFF2A2A2A).copy(alpha = 0.85f)
                                     else Color.White.copy(alpha = 0.92f),
                    contentColor   = if (isDark) Color.White else Color(0xFF333333)
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

// ─── Bottone cerchio riutilizzabile ─────────────────────────────────────────
@Composable
private fun MapCircleButton(
    modifier: Modifier = Modifier,
    backgroundColor: Color = Color.Black.copy(alpha = 0.40f),
    onClick: () -> Unit,
    content: @Composable () -> Unit
) {
    Surface(
        onClick  = onClick,
        shape    = CircleShape,
        color    = backgroundColor,
        shadowElevation = 4.dp,
        modifier = modifier.size(44.dp)
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
            content()
        }
    }
}
