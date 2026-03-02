package app.dove.venezia.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val LightColors = lightColorScheme(
    primary            = VeneziaPrimary,        // #C2452D — corallo veneziano
    onPrimary          = VeneziaOnPrimary,
    primaryContainer   = VeneziaContainer,
    onPrimaryContainer = Color(0xFF410001),
    background         = Color.White,
    surface            = Color.White,
    surfaceVariant     = Color(0xFFF5F5F5),
)

private val DarkColors = darkColorScheme(
    primary            = VeneziaPrimaryDark,    // #E06D51 — corallo più chiaro in dark (come iOS)
    onPrimary          = Color(0xFF1A0000),
    primaryContainer   = Color(0xFF7A3520),  // schiarito per migliore contrasto WCAG
    onPrimaryContainer = VeneziaContainer,
    background         = Color(0xFF121212),
    surface            = Color(0xFF1E1E1E),
    surfaceVariant     = Color(0xFF2A2A2A),
)

@Composable
fun DoVeTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else      -> LightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography  = DoVeTypography,
        content     = content
    )
}
