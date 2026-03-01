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

private val VeneziaOnPrimaryContainer = Color(0xFF410001)
private val VeneziaDarkPrimary        = Color(0xFFFFB4A9)
private val VeneziaDarkOnPrimary      = Color(0xFF690001)
private val VeneziaDarkContainer      = Color(0xFF930001)

private val LightColors = lightColorScheme(
    primary            = VeneziaPrimary,
    onPrimary          = VeneziaOnPrimary,
    primaryContainer   = VeneziaContainer,
    onPrimaryContainer = VeneziaOnPrimaryContainer,
    background         = Color.White,
    surface            = Color.White,
    surfaceVariant     = Color(0xFFF5F5F5),
)

private val DarkColors = darkColorScheme(
    primary            = VeneziaDarkPrimary,
    onPrimary          = VeneziaDarkOnPrimary,
    primaryContainer   = VeneziaDarkContainer,
    onPrimaryContainer = VeneziaContainer,
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
