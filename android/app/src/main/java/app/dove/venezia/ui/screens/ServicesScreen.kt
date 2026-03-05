package app.dove.venezia.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.dove.venezia.R
import app.dove.venezia.ui.theme.PharmacyOpen
import app.dove.venezia.ui.theme.ServiceAcquaAlta
import app.dove.venezia.ui.theme.ServiceEventi
import app.dove.venezia.ui.theme.ServiceVaporetti
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.viewmodel.PharmacyViewModel
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServicesScreen(
    viewModel: PharmacyViewModel,
    onPharmaciesClick: () -> Unit,
    onBack: () -> Unit
) {
    var appeared by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadData()
        delay(50)
        appeared = true
    }

    val totalCount by viewModel.totalCount.collectAsState()
    val openCount by viewModel.openCount.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.services_title),
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(8.dp))

            // Header icon
            AnimatedVisibility(
                visible = appeared,
                enter = fadeIn(tween(600))
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        painter = painterResource(R.drawable.ic_services_header),
                        contentDescription = null,
                        modifier = Modifier.size(52.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = stringResource(R.string.services_subtitle),
                        style = MaterialTheme.typography.bodyMedium.copy(
                            fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                        ),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(Modifier.height(32.dp))

            // DISPONIBILI label
            AnimatedVisibility(
                visible = appeared,
                enter = fadeIn(tween(600, delayMillis = 200))
            ) {
                Text(
                    text = stringResource(R.string.services_available),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    letterSpacing = 2.sp,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }

            // Pharmacy card
            AnimatedVisibility(
                visible = appeared,
                enter = fadeIn(tween(400, delayMillis = 350)) +
                        slideInVertically(tween(400, delayMillis = 350)) { it / 4 }
            ) {
                ServiceCardComposable(
                    iconRes = R.drawable.ic_pharmacy,
                    iconColor = PharmacyOpen,
                    title = stringResource(R.string.pharmacies_title),
                    subtitle = if (totalCount > 0)
                        stringResource(R.string.pharmacies_open_count, openCount, totalCount)
                    else "",
                    badgeCount = if (openCount > 0) openCount else null,
                    onClick = onPharmaciesClick
                )
            }

            Spacer(Modifier.height(28.dp))

            // PROSSIMAMENTE
            AnimatedVisibility(
                visible = appeared,
                enter = fadeIn(tween(600, delayMillis = 500))
            ) {
                Column {
                    Text(
                        text = stringResource(R.string.services_coming_soon),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                    )

                    ComingSoonRow(
                        iconRes = R.drawable.ic_acqua_alta,
                        color = ServiceAcquaAlta,
                        title = stringResource(R.string.service_acqua_alta)
                    )
                    ComingSoonRow(
                        iconRes = R.drawable.ic_vaporetti,
                        color = ServiceVaporetti,
                        title = stringResource(R.string.service_vaporetti)
                    )
                    ComingSoonRow(
                        iconRes = R.drawable.ic_eventi,
                        color = ServiceEventi,
                        title = stringResource(R.string.service_eventi)
                    )
                }
            }

            Spacer(Modifier.height(40.dp))
        }
    }
}

@Composable
private fun ServiceCardComposable(
    iconRes: Int,
    iconColor: Color,
    title: String,
    subtitle: String,
    badgeCount: Int?,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(iconColor.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    painter = painterResource(iconRes),
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                    tint = iconColor
                )
            }

            Spacer(Modifier.width(16.dp))

            // Text
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    fontFamily = SotoportegoFontFamily,
                    fontSize = 20.sp,
                    color = MaterialTheme.colorScheme.onSurface
                )
                if (subtitle.isNotEmpty()) {
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Badge + chevron
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (badgeCount != null) {
                    Box(
                        modifier = Modifier
                            .size(26.dp)
                            .clip(CircleShape)
                            .background(PharmacyOpen),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "$badgeCount",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                )
            }
        }
    }
}

@Composable
private fun ComingSoonRow(
    iconRes: Int,
    color: Color,
    title: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(color.copy(alpha = 0.06f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                painter = painterResource(iconRes),
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = color.copy(alpha = 0.4f)
            )
        }

        Spacer(Modifier.width(14.dp))

        Text(
            text = title,
            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.35f),
            modifier = Modifier.weight(1f)
        )

        Text(
            text = stringResource(R.string.coming_soon_badge),
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.5.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f),
            modifier = Modifier
                .clip(RoundedCornerShape(50))
                .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.04f))
                .padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}
