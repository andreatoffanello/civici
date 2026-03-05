package app.dove.venezia.ui.screens

import android.Manifest
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.location.LocationManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import app.dove.venezia.R
import app.dove.venezia.data.model.Pharmacy
import app.dove.venezia.ui.theme.PharmacyClosed
import app.dove.venezia.ui.theme.PharmacyOpen
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.ui.theme.VeneziaPrimary
import app.dove.venezia.viewmodel.PharmacyUiState
import app.dove.venezia.viewmodel.PharmacyViewModel
import app.dove.venezia.viewmodel.PharmacyWithDistance
import kotlinx.coroutines.delay
import org.maplibre.android.MapLibre
import org.maplibre.android.annotations.IconFactory
import org.maplibre.android.annotations.MarkerOptions
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.geometry.LatLngBounds
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.util.concurrent.atomic.AtomicBoolean

private const val OPENFREEMAP_STYLE = "https://tiles.openfreemap.org/styles/positron"
private const val OPENFREEMAP_STYLE_DARK = "https://tiles.openfreemap.org/styles/dark"
private val VENICE_CENTER = LatLng(45.4371, 12.3326)

private enum class ViewMode { MAP, LIST }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PharmacyListScreen(
    viewModel: PharmacyViewModel,
    onPharmacyClick: (String) -> Unit,
    onBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    var appeared by remember { mutableStateOf(false) }
    var viewMode by remember { mutableStateOf(ViewMode.MAP) }

    val locationLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) requestLocation(context, viewModel)
    }

    LaunchedEffect(Unit) {
        viewModel.loadData()
        locationLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
        delay(50)
        appeared = true
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.pharmacies_title),
                        fontFamily = SotoportegoFontFamily,
                        fontSize = 20.sp
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.back)
                        )
                    }
                },
                actions = {
                    // Map/List toggle
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f))
                            .padding(2.dp)
                    ) {
                        ToggleButton(
                            icon = Icons.Default.Map,
                            selected = viewMode == ViewMode.MAP,
                            onClick = { viewMode = ViewMode.MAP }
                        )
                        ToggleButton(
                            icon = Icons.Default.List,
                            selected = viewMode == ViewMode.LIST,
                            onClick = { viewMode = ViewMode.LIST }
                        )
                    }
                    Spacer(Modifier.width(8.dp))
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { padding ->
        when (val state = uiState) {
            is PharmacyUiState.Loading -> {
                Box(
                    Modifier.fillMaxSize().padding(padding),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                }
            }
            is PharmacyUiState.Error -> {
                Box(
                    Modifier.fillMaxSize().padding(padding),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        stringResource(R.string.error_loading),
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }
            is PharmacyUiState.Ready -> {
                when (viewMode) {
                    ViewMode.MAP -> PharmacyMapContent(
                        state = state,
                        viewModel = viewModel,
                        onPharmacyClick = onPharmacyClick,
                        padding = padding
                    )
                    ViewMode.LIST -> PharmacyList(
                        open = state.open,
                        closed = state.closed,
                        openCount = state.openCount,
                        totalCount = state.totalCount,
                        appeared = appeared,
                        onPharmacyClick = onPharmacyClick,
                        padding = padding
                    )
                }
            }
        }
    }
}

@Composable
private fun ToggleButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    selected: Boolean,
    onClick: () -> Unit
) {
    IconButton(
        onClick = onClick,
        modifier = Modifier
            .size(32.dp)
            .clip(RoundedCornerShape(6.dp))
            .background(if (selected) VeneziaPrimary else Color.Transparent)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (selected) Color.White else MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(18.dp)
        )
    }
}

// ─── Map Content ────────────────────────────────────────────────────────────

@Composable
private fun PharmacyMapContent(
    state: PharmacyUiState.Ready,
    viewModel: PharmacyViewModel,
    onPharmacyClick: (String) -> Unit,
    padding: PaddingValues
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val isDark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val mapStyleUrl = if (isDark) OPENFREEMAP_STYLE_DARK else OPENFREEMAP_STYLE
    val allPharmacies = (state.open + state.closed).map { it.pharmacy }

    var mapRef by remember { mutableStateOf<MapLibreMap?>(null) }
    var selectedPharmacy by remember { mutableStateOf<Pharmacy?>(null) }
    val setupInitiated = remember { AtomicBoolean(false) }

    MapLibre.getInstance(context)
    val mapView = remember { MapView(context) }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> mapView.onStart()
                Lifecycle.Event.ON_RESUME -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE -> mapView.onPause()
                Lifecycle.Event.ON_STOP -> mapView.onStop()
                Lifecycle.Event.ON_DESTROY -> mapView.onDestroy()
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    Box(modifier = Modifier.fillMaxSize().padding(padding)) {
        AndroidView(
            factory = { mapView },
            modifier = Modifier.fillMaxSize(),
            update = { mv ->
                if (setupInitiated.compareAndSet(false, true)) {
                    mv.getMapAsync { map ->
                        mapRef = map
                        map.setStyle(Style.Builder().fromUri(mapStyleUrl)) { style ->
                            // Add pharmacy markers
                            addPharmacyMarkers(map, allPharmacies, context)

                            // Center on user location or Venice
                            val userLoc = viewModel.uiState.value.let {
                                // Try to get user location from the viewmodel
                                null
                            }
                            val target = VENICE_CENTER
                            map.animateCamera(
                                CameraUpdateFactory.newCameraPosition(
                                    CameraPosition.Builder()
                                        .target(target)
                                        .zoom(13.5)
                                        .build()
                                ),
                                1000
                            )

                            // Marker click
                            map.setOnMarkerClickListener { marker ->
                                val pharmacy = allPharmacies.find { it.name == marker.title }
                                selectedPharmacy = pharmacy
                                pharmacy?.let {
                                    map.animateCamera(
                                        CameraUpdateFactory.newLatLng(LatLng(it.lat, it.lng)),
                                        300
                                    )
                                }
                                true
                            }

                            // Map click to deselect
                            map.addOnMapClickListener {
                                selectedPharmacy = null
                                true
                            }

                            // Enable location component
                            try {
                                @Suppress("MissingPermission")
                                map.locationComponent.apply {
                                    activateLocationComponent(
                                        org.maplibre.android.location.LocationComponentActivationOptions
                                            .builder(context, style)
                                            .build()
                                    )
                                    isLocationComponentEnabled = true
                                    cameraMode = org.maplibre.android.location.modes.CameraMode.NONE
                                    renderMode = org.maplibre.android.location.modes.RenderMode.COMPASS
                                }
                            } catch (_: Exception) {}
                        }
                    }
                }
            }
        )

        // Status header overlay
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f))
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(if (state.openCount > 0) PharmacyOpen else PharmacyClosed)
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = stringResource(R.string.pharmacies_open_count, state.openCount, state.totalCount),
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Center on location button
        IconButton(
            onClick = {
                mapRef?.let { map ->
                    map.animateCamera(
                        CameraUpdateFactory.newCameraPosition(
                            CameraPosition.Builder()
                                .target(VENICE_CENTER)
                                .zoom(13.5)
                                .build()
                        ),
                        500
                    )
                }
            },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(
                    end = 16.dp,
                    bottom = if (selectedPharmacy != null) 120.dp else 16.dp
                )
                .size(44.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.9f))
        ) {
            Icon(
                Icons.Default.MyLocation,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.onSurface
            )
        }

        // Selected pharmacy card
        selectedPharmacy?.let { pharmacy ->
            val isOpen = pharmacy.isOpen()
            val item = (state.open + state.closed).find { it.pharmacy.id == pharmacy.id }

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .padding(12.dp)
                    .clickable { onPharmacyClick(pharmacy.id) },
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                elevation = CardDefaults.cardElevation(6.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Icon
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(
                                (if (isOpen) PharmacyOpen else PharmacyClosed).copy(alpha = 0.1f)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.ic_pharmacy),
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                            tint = if (isOpen) PharmacyOpen else PharmacyClosed
                        )
                    }

                    Spacer(Modifier.width(12.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = pharmacy.name,
                            fontFamily = SotoportegoFontFamily,
                            fontSize = 16.sp,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = pharmacy.address,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = stringResource(
                                    if (isOpen) R.string.pharmacy_open else R.string.pharmacy_closed
                                ),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = if (isOpen) PharmacyOpen else PharmacyClosed
                            )
                            pharmacy.todayHoursFormatted()?.let { hours ->
                                Text(
                                    text = hours,
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                                )
                            }
                            item?.formattedDistance?.let { dist ->
                                Text(
                                    text = "· $dist",
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                                )
                            }
                        }
                    }

                    Icon(
                        painter = painterResource(R.drawable.ic_navigate),
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                    )
                }
            }
        }
    }
}

private fun addPharmacyMarkers(map: MapLibreMap, pharmacies: List<Pharmacy>, context: Context) {
    val iconFactory = IconFactory.getInstance(context)
    val density = context.resources.displayMetrics.density

    val openIcon = createCircleMarkerBitmap(density, PharmacyOpen.toArgb())
    val closedIcon = createCircleMarkerBitmap(density, PharmacyClosed.toArgb())

    pharmacies.forEach { pharmacy ->
        val isOpen = pharmacy.isOpen()
        val bitmap = if (isOpen) openIcon else closedIcon

        map.addMarker(
            MarkerOptions()
                .position(LatLng(pharmacy.lat, pharmacy.lng))
                .title(pharmacy.name)
                .snippet(if (isOpen) "Aperta" else "Chiusa")
                .icon(iconFactory.fromBitmap(bitmap))
        )
    }
}

private fun createCircleMarkerBitmap(density: Float, color: Int): Bitmap {
    val size = (28 * density).toInt()
    val crossSize = (12 * density)
    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    // Circle background
    val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        this.color = color
        style = Paint.Style.FILL
    }
    canvas.drawOval(RectF(0f, 0f, size.toFloat(), size.toFloat()), bgPaint)

    // White cross
    val crossPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        this.color = android.graphics.Color.WHITE
        style = Paint.Style.STROKE
        strokeWidth = 2.5f * density
        strokeCap = Paint.Cap.ROUND
    }
    val cx = size / 2f
    val cy = size / 2f
    val half = crossSize / 2
    canvas.drawLine(cx - half, cy, cx + half, cy, crossPaint)
    canvas.drawLine(cx, cy - half, cx, cy + half, crossPaint)

    return bitmap
}

// ─── List Content ────────────────────────────────────────────────────────────

@Composable
private fun PharmacyList(
    open: List<PharmacyWithDistance>,
    closed: List<PharmacyWithDistance>,
    openCount: Int,
    totalCount: Int,
    appeared: Boolean,
    onPharmacyClick: (String) -> Unit,
    padding: PaddingValues
) {
    val timeFormatter = remember { DateTimeFormatter.ofPattern("HH:mm") }

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(padding),
        contentPadding = PaddingValues(bottom = 24.dp)
    ) {
        item {
            AnimatedVisibility(
                visible = appeared,
                enter = fadeIn(tween(500))
            ) {
                StatusHeader(openCount, totalCount, timeFormatter)
            }
        }

        if (open.isNotEmpty()) {
            item {
                SectionHeader(
                    text = stringResource(R.string.pharmacies_open_now),
                    appeared = appeared,
                    delayMs = 200
                )
            }
            itemsIndexed(open, key = { _, it -> it.pharmacy.id }) { idx, item ->
                AnimatedVisibility(
                    visible = appeared,
                    enter = fadeIn(tween(300, delayMillis = 300 + idx * 50)) +
                            slideInVertically(tween(300, delayMillis = 300 + idx * 50)) { it / 3 }
                ) {
                    PharmacyRow(
                        item = item,
                        isOpen = true,
                        onClick = { onPharmacyClick(item.pharmacy.id) }
                    )
                }
                if (idx < open.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 72.dp),
                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                    )
                }
            }
        }

        if (closed.isNotEmpty()) {
            item {
                SectionHeader(
                    text = stringResource(R.string.pharmacies_closed_now),
                    appeared = appeared,
                    delayMs = 300 + open.size * 50
                )
            }
            itemsIndexed(closed, key = { _, it -> it.pharmacy.id }) { idx, item ->
                AnimatedVisibility(
                    visible = appeared,
                    enter = fadeIn(tween(300, delayMillis = 400 + open.size * 50 + idx * 50)) +
                            slideInVertically(tween(300, delayMillis = 400 + open.size * 50 + idx * 50)) { it / 3 }
                ) {
                    PharmacyRow(
                        item = item,
                        isOpen = false,
                        onClick = { onPharmacyClick(item.pharmacy.id) }
                    )
                }
                if (idx < closed.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 72.dp),
                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                    )
                }
            }
        }
    }
}

@Composable
private fun StatusHeader(openCount: Int, totalCount: Int, timeFormatter: DateTimeFormatter) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(if (openCount > 0) PharmacyOpen else PharmacyClosed)
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = stringResource(R.string.pharmacies_open_count, openCount, totalCount),
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Text(
            text = LocalTime.now().format(timeFormatter),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )
    }
}

@Composable
private fun SectionHeader(text: String, appeared: Boolean, delayMs: Int) {
    AnimatedVisibility(
        visible = appeared,
        enter = fadeIn(tween(400, delayMillis = delayMs))
    ) {
        Text(
            text = text.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            letterSpacing = 2.sp,
            modifier = Modifier.padding(start = 20.dp, top = 16.dp, bottom = 8.dp)
        )
    }
}

@Composable
private fun PharmacyRow(
    item: PharmacyWithDistance,
    isOpen: Boolean,
    onClick: () -> Unit
) {
    val pharmacy = item.pharmacy

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(pharmacy.areaColor.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                painter = painterResource(R.drawable.ic_pharmacy),
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = pharmacy.areaColor
            )
        }

        Spacer(Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = pharmacy.name,
                fontFamily = SotoportegoFontFamily,
                fontSize = 16.sp,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = pharmacy.address,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            pharmacy.todayHoursFormatted()?.let { hours ->
                Text(
                    text = hours,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                    fontSize = 11.sp
                )
            }
        }

        Column(
            horizontalAlignment = Alignment.End,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(
                        (if (isOpen) PharmacyOpen else PharmacyClosed).copy(alpha = 0.1f)
                    )
                    .padding(horizontal = 8.dp, vertical = 3.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(if (isOpen) PharmacyOpen else PharmacyClosed)
                )
                Text(
                    text = stringResource(if (isOpen) R.string.pharmacy_open else R.string.pharmacy_closed),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isOpen) PharmacyOpen else PharmacyClosed
                )
            }

            item.formattedDistance?.let { dist ->
                Text(
                    text = dist,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                    fontSize = 11.sp
                )
            }
        }
    }
}

@Suppress("MissingPermission")
private fun requestLocation(context: Context, viewModel: PharmacyViewModel) {
    try {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val location = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            ?: lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
        viewModel.updateLocation(location)
    } catch (_: Exception) {}
}
