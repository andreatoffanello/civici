package app.dove.venezia.ui.screens

import android.content.Intent
import android.location.Location
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.dove.venezia.R
import app.dove.venezia.data.model.Pharmacy
import app.dove.venezia.ui.theme.PharmacyClosed
import app.dove.venezia.ui.theme.PharmacyOpen
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.ui.theme.VeneziaPrimary
import app.dove.venezia.viewmodel.PharmacyUiState
import app.dove.venezia.viewmodel.PharmacyViewModel

@Composable
fun PharmacyDetailScreen(
    pharmacyId: String,
    viewModel: PharmacyViewModel,
    onBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    val pharmacy = remember(uiState, pharmacyId) {
        when (val state = uiState) {
            is PharmacyUiState.Ready ->
                (state.open + state.closed).firstOrNull { it.pharmacy.id == pharmacyId }?.pharmacy
            else -> null
        }
    }

    if (pharmacy == null) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(stringResource(R.string.error_loading))
        }
        return
    }

    val isOpen = pharmacy.isOpen()
    val distance = remember(uiState, pharmacyId) {
        when (val state = uiState) {
            is PharmacyUiState.Ready ->
                (state.open + state.closed).firstOrNull { it.pharmacy.id == pharmacyId }?.formattedDistance
            else -> null
        }
    }

    Box(Modifier.fillMaxSize()) {
        // Map placeholder background
        Box(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.surfaceVariant)
        ) {
            // Map marker indicator
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                    ),
                    elevation = CardDefaults.cardElevation(4.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.ic_pharmacy),
                            contentDescription = null,
                            modifier = Modifier.size(20.dp),
                            tint = if (isOpen) PharmacyOpen else PharmacyClosed
                        )
                        distance?.let { d ->
                            Text(
                                text = d,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                // Map pin triangle
                Box(
                    modifier = Modifier
                        .size(12.dp, 6.dp)
                        .background(
                            MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
                            shape = TriangleShape
                        )
                )
            }

            // Coordinates label
            Text(
                text = "%.4f, %.4f".format(pharmacy.lat, pharmacy.lng),
                fontSize = 10.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 80.dp)
            )
        }

        // Back button
        IconButton(
            onClick = onBack,
            modifier = Modifier
                .padding(start = 8.dp, top = 40.dp)
                .align(Alignment.TopStart)
                .size(40.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.85f))
        ) {
            Icon(
                Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = stringResource(R.string.back),
                modifier = Modifier.size(20.dp)
            )
        }

        // Bottom card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter),
            shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            ),
            elevation = CardDefaults.cardElevation(8.dp)
        ) {
            Column(modifier = Modifier.padding(top = 12.dp, bottom = 24.dp)) {
                // Drag indicator
                Box(
                    modifier = Modifier
                        .width(36.dp)
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))
                        .align(Alignment.CenterHorizontally)
                )

                Spacer(Modifier.height(16.dp))

                // Name + status
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp),
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = pharmacy.name,
                            fontFamily = SotoportegoFontFamily,
                            fontSize = 22.sp,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(Modifier.height(2.dp))
                        Text(
                            text = pharmacy.address,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    StatusBadge(isOpen)
                }

                Spacer(Modifier.height(16.dp))

                // Info rows
                InfoRow(
                    iconRes = R.drawable.ic_clock,
                    label = stringResource(R.string.pharmacy_hours_label),
                    value = pharmacy.todayHoursFormatted()
                        ?: stringResource(R.string.pharmacy_closed)
                )
                HorizontalDivider(
                    modifier = Modifier.padding(start = 60.dp),
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                )
                InfoRow(
                    iconRes = R.drawable.ic_phone,
                    label = stringResource(R.string.pharmacy_phone_label),
                    value = pharmacy.phone
                )
                HorizontalDivider(
                    modifier = Modifier.padding(start = 60.dp),
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                )
                InfoRow(
                    iconRes = R.drawable.ic_pin,
                    label = stringResource(R.string.pharmacy_area_label),
                    value = pharmacy.areaName
                )

                Spacer(Modifier.height(20.dp))

                // Action buttons
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = { callPharmacy(context, pharmacy) },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.ic_phone),
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            stringResource(R.string.pharmacy_call),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp
                        )
                    }

                    Button(
                        onClick = { navigateToPharmacy(context, pharmacy) },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = VeneziaPrimary,
                            contentColor = Color.White
                        )
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.ic_navigate),
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            stringResource(R.string.naviga),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusBadge(isOpen: Boolean) {
    val color = if (isOpen) PharmacyOpen else PharmacyClosed
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(color.copy(alpha = 0.1f))
            .padding(horizontal = 10.dp, vertical = 6.dp)
    ) {
        Box(
            modifier = Modifier
                .size(7.dp)
                .clip(CircleShape)
                .background(color)
        )
        Text(
            text = stringResource(if (isOpen) R.string.pharmacy_open else R.string.pharmacy_closed),
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = color
        )
    }
}

@Composable
private fun InfoRow(iconRes: Int, label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            painter = painterResource(iconRes),
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )
        Spacer(Modifier.width(16.dp))
        Column {
            Text(
                text = label.uppercase(),
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                letterSpacing = 0.5.sp
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

private fun callPharmacy(context: android.content.Context, pharmacy: Pharmacy) {
    val cleaned = pharmacy.phone.replace(" ", "")
    val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$cleaned"))
    context.startActivity(intent)
}

private fun navigateToPharmacy(context: android.content.Context, pharmacy: Pharmacy) {
    val uri = Uri.parse("geo:${pharmacy.lat},${pharmacy.lng}?q=${pharmacy.lat},${pharmacy.lng}(${Uri.encode(pharmacy.name)})")
    val intent = Intent(Intent.ACTION_VIEW, uri)
    context.startActivity(intent)
}

// Simple triangle shape for map pin
private val TriangleShape = object : androidx.compose.ui.graphics.Shape {
    override fun createOutline(
        size: androidx.compose.ui.geometry.Size,
        layoutDirection: androidx.compose.ui.unit.LayoutDirection,
        density: androidx.compose.ui.unit.Density
    ): androidx.compose.ui.graphics.Outline {
        val path = androidx.compose.ui.graphics.Path().apply {
            moveTo(0f, 0f)
            lineTo(size.width, 0f)
            lineTo(size.width / 2, size.height)
            close()
        }
        return androidx.compose.ui.graphics.Outline.Generic(path)
    }
}
