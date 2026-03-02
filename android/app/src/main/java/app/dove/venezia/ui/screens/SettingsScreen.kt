package app.dove.venezia.ui.screens

import android.app.Activity
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import android.os.LocaleList
import androidx.core.os.LocaleListCompat
import app.dove.venezia.R
import app.dove.venezia.data.AppLanguage
import app.dove.venezia.data.AppPrefs
import app.dove.venezia.data.AppTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(onBack: () -> Unit) {
    val context  = LocalContext.current
    val theme    by AppPrefs.theme.collectAsState()
    val language by AppPrefs.language.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.back))
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(Modifier.height(8.dp))

            // ── Tema ──────────────────────────────────────────────────────────
            Text(
                text     = stringResource(R.string.settings_theme),
                style    = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(vertical = 8.dp)
            )
            listOf(
                AppTheme.SYSTEM to stringResource(R.string.theme_system),
                AppTheme.LIGHT  to stringResource(R.string.theme_light),
                AppTheme.DARK   to stringResource(R.string.theme_dark)
            ).forEach { (t, label) ->
                RadioRow(
                    label    = label,
                    selected = theme == t,
                    onSelect = { AppPrefs.setTheme(t) }
                )
            }

            HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))

            // ── Lingua ────────────────────────────────────────────────────────
            Text(
                text     = stringResource(R.string.settings_language),
                style    = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(vertical = 8.dp)
            )
            listOf(
                AppLanguage.SYSTEM  to stringResource(R.string.lang_system),
                AppLanguage.ITALIAN to stringResource(R.string.lang_italian),
                AppLanguage.ENGLISH to stringResource(R.string.lang_english)
            ).forEach { (lang, label) ->
                RadioRow(
                    label    = label,
                    selected = language == lang,
                    onSelect = {
                        AppPrefs.setLanguage(lang)
                        val localeTag = when (lang) {
                            AppLanguage.ITALIAN -> "it"
                            AppLanguage.ENGLISH -> "en"
                            AppLanguage.SYSTEM  -> ""
                        }
                        AppCompatDelegate.setApplicationLocales(
                            if (localeTag.isEmpty()) LocaleListCompat.wrap(LocaleList.getEmptyLocaleList())
                            else LocaleListCompat.forLanguageTags(localeTag)
                        )
                        // Su API < 33 forziamo il recreate manualmente
                        (context as? Activity)?.recreate()
                    }
                )
            }
        }
    }
}

@Composable
private fun RadioRow(label: String, selected: Boolean, onSelect: () -> Unit) {
    Row(
        modifier          = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(selected = selected, onClick = onSelect)
        Text(
            text     = label,
            style    = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.padding(start = 8.dp)
        )
    }
}
