package app.dove.venezia.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.dove.venezia.R
import app.dove.venezia.data.model.ZonaNormale
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.ui.theme.VeneziaPrimary
import app.dove.venezia.viewmodel.ZonaNormaleUiState
import app.dove.venezia.viewmodel.ZonaNormaleViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StreetNumbersScreen(
    zonaCode: String,
    street: String,
    viewModel: ZonaNormaleViewModel,
    onCivicoClick: (numero: String, lat: Double, lng: Double, via: String) -> Unit,
    onBack: () -> Unit
) {
    val zona        = ZonaNormale.fromCode(zonaCode)
    val accentColor = zona?.color ?: MaterialTheme.colorScheme.primary
    val uiState     by viewModel.uiState.collectAsState()
    val scope       = rememberCoroutineScope()

    LaunchedEffect(zonaCode, street) { viewModel.loadNumbers(zonaCode, street) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text          = (zona?.displayName ?: zonaCode).uppercase(),
                            fontFamily    = SotoportegoFontFamily,
                            fontSize      = 11.sp,
                            letterSpacing = 2.sp,
                            color         = accentColor.copy(alpha = 0.7f)
                        )
                        Text(
                            text          = street,
                            fontFamily    = SotoportegoFontFamily,
                            fontSize      = 16.sp,
                            letterSpacing = 0.5.sp,
                            color         = accentColor,
                            fontWeight    = FontWeight.Normal
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.back))
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            when (val state = uiState) {
                is ZonaNormaleUiState.Loading -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = accentColor)
                    }
                }
                is ZonaNormaleUiState.Ready -> {
                    if (state.items.isEmpty()) {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(
                                text  = stringResource(R.string.no_data_zona),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    } else {
                        Text(
                            text     = stringResource(R.string.civici_count, state.items.size),
                            style    = MaterialTheme.typography.labelMedium,
                            color    = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp)
                        )
                        LazyColumn(
                            contentPadding      = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                            verticalArrangement = Arrangement.spacedBy(0.dp)
                        ) {
                            items(state.items, key = { it }) { numero ->
                                CivicoPillRow(
                                    numero      = numero,
                                    accentColor = VeneziaPrimary,
                                    onClick     = {
                                        scope.launch {
                                            val coord = viewModel.getCoordinate(zonaCode, street, numero)
                                            if (coord != null) onCivicoClick(numero, coord.lat, coord.lng, street)
                                        }
                                    }
                                )
                                HorizontalDivider(
                                    modifier  = Modifier.padding(start = 80.dp),
                                    thickness = 0.5.dp,
                                    color     = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
