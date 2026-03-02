package app.dove.venezia.ui.screens

import androidx.compose.foundation.Image
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.foundation.border
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.dove.venezia.R
import app.dove.venezia.data.model.Sestiere
import app.dove.venezia.data.model.ZonaNormale
import app.dove.venezia.ui.theme.SotoportegoFontFamily
import app.dove.venezia.ui.theme.VeneziaPrimary
import app.dove.venezia.ui.theme.VeneziaPrimaryDark
import app.dove.venezia.viewmodel.SearchUiState
import app.dove.venezia.viewmodel.SearchViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class, ExperimentalComposeUiApi::class)
@Composable
fun SearchScreen(
    sestiereCode: String,
    viewModel: SearchViewModel,
    onCivicoClick: (numero: String, lat: Double, lng: Double) -> Unit,
    onBack: () -> Unit
) {
    val sestiere = Sestiere.fromCode(sestiereCode)
    val zona = if (sestiere == null) ZonaNormale.fromCode(sestiereCode) else null
    val zonaDisplay = zona?.displayName
    val isDarkTheme = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val accentColor = sestiere?.color ?: zona?.color ?: if (isDarkTheme) VeneziaPrimaryDark else VeneziaPrimary
    // Pill corallo: più chiaro in dark mode per migliore contrasto
    val pillColor   = if (isDarkTheme) VeneziaPrimaryDark else VeneziaPrimary
    val uiState by viewModel.uiState.collectAsState()
    val query by viewModel.query.collectAsState()
    val scope = rememberCoroutineScope()
    val focusManager = LocalFocusManager.current
    val focusRequester = FocusRequester()
    val keyboardController = LocalSoftwareKeyboardController.current

    LaunchedEffect(sestiereCode) { viewModel.loadSestiere(sestiereCode) }

    // Focus automatico sul campo di ricerca + apertura tastiera
    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(300)
        focusRequester.requestFocus()
        keyboardController?.show()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        val silhouette = sestiere?.drawableRes ?: zona?.drawableRes
                        silhouette?.let { res ->
                            Image(
                                painter = painterResource(res),
                                contentDescription = null,
                                colorFilter = ColorFilter.tint(accentColor.copy(alpha = 0.7f)),
                                contentScale = ContentScale.Fit,
                                modifier = Modifier.size(32.dp)
                            )
                            Spacer(Modifier.width(10.dp))
                        }
                        Text(
                            text = (sestiere?.displayName ?: zonaDisplay ?: sestiereCode).uppercase(),
                            fontFamily = SotoportegoFontFamily,
                            fontSize = 18.sp,
                            letterSpacing = 2.sp,
                            color = accentColor
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            // Campo ricerca
            OutlinedTextField(
                value = query,
                onValueChange = viewModel::setQuery,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp).focusRequester(focusRequester),
                placeholder = {
                    Text(stringResource(R.string.search_placeholder), color = MaterialTheme.colorScheme.onSurfaceVariant)
                },
                leadingIcon = {
                    Text("#", modifier = Modifier.padding(start = 12.dp), fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                },
                trailingIcon = {
                    if (query.isNotEmpty()) {
                        IconButton(onClick = { viewModel.setQuery("") }) {
                            Icon(Icons.Default.Clear, contentDescription = null,
                                tint = accentColor.copy(alpha = 0.7f))
                        }
                    }
                },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Number,
                    imeAction = ImeAction.Done
                ),
                keyboardActions = KeyboardActions(onDone = { focusManager.clearFocus() }),
                singleLine = true,
                shape = RoundedCornerShape(28.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = accentColor,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)
                )
            )

            when (val state = uiState) {
                is SearchUiState.Loading -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = accentColor)
                    }
                }
                is SearchUiState.Ready -> {
                    if (state.numbers.isEmpty() && query.isEmpty()) {
                        // Zona senza dati civici
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(
                                text = stringResource(R.string.no_data_zona),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    } else if (state.numbers.isEmpty() && query.isNotEmpty()) {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(stringResource(R.string.no_results, query),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    } else {
                        // Conteggio risultati
                        if (query.isNotEmpty()) {
                            Text(
                                text = "${state.numbers.size} risultati",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp)
                            )
                        }
                        LazyColumn(contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                            verticalArrangement = Arrangement.spacedBy(0.dp)) {
                            items(state.numbers, key = { it }) { numero ->
                                CivicoPillRow(
                                    numero = numero,
                                    accentColor = pillColor,
                                    onClick = {
                                        focusManager.clearFocus()
                                        scope.launch {
                                            val coord = viewModel.getCoordinate(sestiereCode, numero)
                                            if (coord != null) onCivicoClick(numero, coord.lat, coord.lng)
                                        }
                                    }
                                )
                                HorizontalDivider(
                                    modifier = Modifier.padding(start = 80.dp),
                                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                                )
                            }
                        }
                    }
                }
                is SearchUiState.Error -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(stringResource(R.string.error_loading))
                    }
                }
            }
        }
    }
}

@Composable
internal fun CivicoPillRow(numero: String, accentColor: Color, onClick: () -> Unit) {
    val isDark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val shape  = RoundedCornerShape(12.dp)

    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 4.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = if (isDark) {
                // Dark mode: bordo corallo definito + sfondo quasi trasparente + testo bianco
                // Evita il brownish degradato dell'alpha-blend su nero
                Modifier
                    .clip(shape)
                    .border(1.5.dp, accentColor.copy(alpha = 0.75f), shape)
                    .background(accentColor.copy(alpha = 0.12f))
                    .padding(horizontal = 20.dp, vertical = 10.dp)
            } else {
                // Light mode: pill tinta leggera senza bordo (invariato)
                Modifier
                    .clip(shape)
                    .background(accentColor.copy(alpha = 0.12f))
                    .padding(horizontal = 20.dp, vertical = 10.dp)
            },
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = numero,
                fontFamily = SotoportegoFontFamily,
                fontSize = 17.sp,
                fontWeight = FontWeight.Normal,
                // Dark: testo bianco (massimo contrasto), light: colore sestiere
                color = if (isDark) Color.White else accentColor
            )
        }
        Spacer(Modifier.weight(1f))
        Icon(
            Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
        )
    }
}
