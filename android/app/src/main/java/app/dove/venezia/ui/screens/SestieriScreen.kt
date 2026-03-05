package app.dove.venezia.ui.screens

import androidx.annotation.DrawableRes
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.dove.venezia.R
import app.dove.venezia.data.model.Sestiere
import app.dove.venezia.data.model.ZonaNormale
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.ui.theme.VeneziaPrimary

@Composable
fun SestieriScreen(
    onSestiereSelected: (String) -> Unit,
    onZonaSelected: (String) -> Unit,
    onServicesClick: () -> Unit,
    onInfoClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    var selectedTab by remember { mutableIntStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar(containerColor = MaterialTheme.colorScheme.surface) {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = { Icon(Icons.Default.Search, contentDescription = null) },
                    label = { Text(stringResource(R.string.tab_cerca)) }
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1; onServicesClick() },
                    icon = { Icon(painterResource(R.drawable.ic_services_header), contentDescription = null, modifier = Modifier.size(24.dp)) },
                    label = { Text(stringResource(R.string.tab_servizi)) }
                )
                NavigationBarItem(
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2; onInfoClick() },
                    icon = { Icon(Icons.Default.Info, contentDescription = null) },
                    label = { Text(stringResource(R.string.tab_info)) }
                )
                NavigationBarItem(
                    selected = selectedTab == 3,
                    onClick = { selectedTab = 3; onSettingsClick() },
                    icon = { Icon(Icons.Default.Settings, contentDescription = null) },
                    label = { Text(stringResource(R.string.tab_impostazioni)) }
                )
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(bottom = 16.dp)
        ) {
            item { DoVeHeader() }

            item {
                Text(
                    text = stringResource(R.string.seleziona_sestiere),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    letterSpacing = 1.sp,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }

            itemsIndexed(Sestiere.entries) { idx, sestiere ->
                SestiereRow(
                    name = sestiere.displayName,
                    color = sestiere.color,
                    silhouetteRes = sestiere.drawableRes,
                    index = idx,
                    onClick = { onSestiereSelected(sestiere.code) }
                )
                HorizontalDivider(
                    modifier = Modifier.padding(start = 20.dp),
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                )
            }

            item { SectionLabel(stringResource(R.string.zone_centro_title)) }
            val sestieriCount = Sestiere.entries.size + 1
            itemsIndexed(ZonaNormale.zoneCentro) { idx, zona ->
                SestiereRow(name = zona.displayName, color = zona.color, silhouetteRes = zona.drawableRes, index = sestieriCount + idx, onClick = { onZonaSelected(zona.code) })
                HorizontalDivider(modifier = Modifier.padding(start = 20.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))
            }

            item { SectionLabel(stringResource(R.string.isole_title)) }
            val isoleBase = sestieriCount + ZonaNormale.zoneCentro.size + 1
            itemsIndexed(ZonaNormale.isole) { idx, zona ->
                SestiereRow(name = zona.displayName, color = zona.color, silhouetteRes = zona.drawableRes, index = isoleBase + idx, onClick = { onZonaSelected(zona.code) })
                HorizontalDivider(modifier = Modifier.padding(start = 20.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))
            }

            item { Spacer(Modifier.height(16.dp)) }
        }
    }
}

@Composable
private fun DoVeHeader() {
    // In dark mode usa logo_dove_white (testo tutto bianco, elegante su sfondo scuro)
    // In light usa logo_dove_alt (DO nero + VE terracotta)
    val isDark  = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val logoRes = if (isDark) R.drawable.logo_dove_white else R.drawable.logo_dove_alt

    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Image(
            painter = painterResource(logoRes),
            contentDescription = "DoVe",
            contentScale = ContentScale.Fit,
            modifier = Modifier.size(160.dp)
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.tagline),
            style = MaterialTheme.typography.bodyMedium.copy(fontStyle = androidx.compose.ui.text.font.FontStyle.Italic),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun SectionLabel(label: String) {
    Text(
        text = label.uppercase(),
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        letterSpacing = 1.sp,
        modifier = Modifier.padding(start = 20.dp, top = 20.dp, bottom = 4.dp)
    )
}

@Composable
private fun SestiereRow(
    name: String,
    color: Color,
    @DrawableRes silhouetteRes: Int?,
    index: Int,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = name.uppercase(),
            fontFamily = SotoportegoFontFamily,
            fontWeight = FontWeight.Normal,
            fontSize = 22.sp,
            letterSpacing = 2.sp,
            color = color,
            modifier = Modifier.weight(1f)
        )
        if (silhouetteRes != null) {
            Image(
                painter = painterResource(id = silhouetteRes),
                contentDescription = null,
                colorFilter = ColorFilter.tint(color.copy(alpha = 0.55f)),
                contentScale = ContentScale.Fit,
                modifier = Modifier.size(54.dp)
            )
        }
    }
}

val Sestiere.drawableRes: Int? get() = when (this) {
    Sestiere.CANNAREGIO  -> R.drawable.sestiere_cannaregio
    Sestiere.CASTELLO    -> R.drawable.sestiere_castello
    Sestiere.DORSODURO   -> R.drawable.sestiere_dorsoduro
    Sestiere.GIUDECCA    -> R.drawable.sestiere_giudecca
    Sestiere.SANTA_CROCE -> R.drawable.sestiere_santa_croce
    Sestiere.SAN_MARCO   -> R.drawable.sestiere_san_marco
    Sestiere.SAN_POLO    -> R.drawable.sestiere_san_polo
}

val ZonaNormale.drawableRes: Int? get() = when (this) {
    ZonaNormale.MURANO       -> R.drawable.isola_murano
    ZonaNormale.BURANO       -> R.drawable.isola_burano
    ZonaNormale.TORCELLO     -> R.drawable.isola_torcello
    ZonaNormale.MAZZORBO     -> R.drawable.isola_mazzorbo
    ZonaNormale.LIDO         -> R.drawable.isola_lido
    ZonaNormale.PELLESTRINA  -> R.drawable.isola_pellestrina
    ZonaNormale.SANT_ERASMO  -> R.drawable.isola_sant_erasmo
    ZonaNormale.VIGNOLE      -> R.drawable.isola_vignole
    ZonaNormale.CERTOSA      -> R.drawable.isola_certosa
    ZonaNormale.SANT_ELENA   -> R.drawable.isola_sant_elena
    ZonaNormale.SACCA_FISOLA -> R.drawable.isola_sacca_fisola
}
