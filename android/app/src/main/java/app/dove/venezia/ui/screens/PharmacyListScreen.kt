package app.dove.venezia.ui.screens

import android.Manifest
import android.content.Context
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.dove.venezia.R
import app.dove.venezia.ui.theme.PharmacyClosed
import app.dove.venezia.ui.theme.PharmacyOpen
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.viewmodel.PharmacyUiState
import app.dove.venezia.viewmodel.PharmacyViewModel
import app.dove.venezia.viewmodel.PharmacyWithDistance
import kotlinx.coroutines.delay
import java.time.LocalTime
import java.time.format.DateTimeFormatter

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

    // Location permission
    val locationLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            requestLocation(context, viewModel)
        }
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
                PharmacyList(
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
        // Status header
        item {
            AnimatedVisibility(
                visible = appeared,
                enter = fadeIn(tween(500))
            ) {
                StatusHeader(openCount, totalCount, timeFormatter)
            }
        }

        // Open section
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

        // Closed section
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
        // Icon
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

        // Name + address + hours
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

        // Distance + status
        Column(
            horizontalAlignment = Alignment.End,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            // Status badge
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

            // Distance
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
