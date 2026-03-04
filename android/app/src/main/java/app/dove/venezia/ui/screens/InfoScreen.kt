package app.dove.venezia.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.dove.venezia.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InfoScreen(onBack: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.info_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 8.dp)
        ) {
            // I civici veneziani
            InfoSection(
                title = stringResource(R.string.info_civici_title),
                body = stringResource(R.string.info_civici_body)
            )

            Spacer(Modifier.height(24.dp))

            // I nizioleti
            InfoSection(
                title = stringResource(R.string.info_nizioleti_title),
                body = stringResource(R.string.info_nizioleti_body)
            )

            Spacer(Modifier.height(24.dp))

            // Credits
            InfoSection(
                title = stringResource(R.string.info_credits_title),
                body = stringResource(R.string.info_credits_body)
            )

            Spacer(Modifier.height(32.dp))

            // Storia del sistema
            Text(
                text = stringResource(R.string.info_history_title),
                style = MaterialTheme.typography.titleLarge
            )

            Spacer(Modifier.height(16.dp))

            InfoSection(
                title = stringResource(R.string.info_history_oral_title),
                body = stringResource(R.string.info_history_oral_body)
            )

            Spacer(Modifier.height(24.dp))

            InfoSection(
                title = stringResource(R.string.info_history_naming_title),
                body = stringResource(R.string.info_history_naming_body)
            )

            Spacer(Modifier.height(24.dp))

            InfoSection(
                title = stringResource(R.string.info_history_napoleon_title),
                body = stringResource(R.string.info_history_napoleon_body)
            )

            Spacer(Modifier.height(24.dp))

            InfoSection(
                title = stringResource(R.string.info_history_austrian_title),
                body = stringResource(R.string.info_history_austrian_body)
            )

            Spacer(Modifier.height(40.dp))

            // Crafted in Venice by [logo]
            val context = LocalContext.current
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        context.startActivity(
                            Intent(Intent.ACTION_VIEW, Uri.parse("https://andreatoffanello.com"))
                        )
                    }
                    .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = stringResource(R.string.crafted_in_venice),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                )
                Image(
                    painter = painterResource(R.drawable.ic_at_logo),
                    contentDescription = "Andrea Toffanello",
                    modifier = Modifier.size(16.dp),
                    colorFilter = ColorFilter.tint(
                        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                    )
                )
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun InfoSection(title: String, body: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleMedium
    )
    Spacer(Modifier.height(8.dp))
    Text(
        text = body,
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}
