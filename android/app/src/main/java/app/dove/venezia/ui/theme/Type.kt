package app.dove.venezia.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.dove.venezia.R

// Font Sotoportego — serif veneziano, usato SOLO per:
// 1. Label sestieri/zone nell'elenco SestieriScreen
// 2. TopBar quando si ricerca (SearchScreen, StreetListScreen, StreetNumbersScreen)
// 3. Nomi via nella lista strade (StreetListScreen)
// 4. Numeri civici nella lista (SearchScreen pill, StreetNumbersScreen)
// 5. Nizioleto nella schermata mappa (ResultScreen)
// Tutto il resto → FontFamily.Default (sistema)
val SotoportegoFontFamily = FontFamily(
    Font(R.font.sotoportego, FontWeight.Normal)
)

// Alias per retrocompatibilità
val NizioletiFontFamily = SotoportegoFontFamily

val DoVeTypography = Typography(
    // Splash logo — immagine, non testo; tenuto system font per sicurezza
    displayLarge = TextStyle(
        fontFamily    = FontFamily.Default,
        fontWeight    = FontWeight.Normal,
        fontSize      = 72.sp,
        lineHeight    = 80.sp,
        letterSpacing = 4.sp
    ),
    headlineLarge = TextStyle(
        fontFamily  = FontFamily.Default,
        fontWeight  = FontWeight.Normal,
        fontSize    = 36.sp,
        lineHeight  = 44.sp
    ),
    // Usato in InfoScreen titoli sezione → sistema
    titleLarge = TextStyle(
        fontFamily    = FontFamily.Default,
        fontWeight    = FontWeight.SemiBold,
        fontSize      = 20.sp,
        lineHeight    = 28.sp,
        letterSpacing = 0.sp
    ),
    // Usato in SettingsScreen sezioni → sistema
    titleMedium = TextStyle(
        fontFamily    = FontFamily.Default,
        fontWeight    = FontWeight.Medium,
        fontSize      = 16.sp,
        lineHeight    = 24.sp,
        letterSpacing = 0.15.sp
    ),
    // Usato in RadioButton labels, ecc. → sistema
    bodyLarge = TextStyle(
        fontFamily    = FontFamily.Default,
        fontWeight    = FontWeight.Normal,
        fontSize      = 16.sp,
        lineHeight    = 24.sp,
        letterSpacing = 0.5.sp
    ),
    bodyMedium = TextStyle(
        fontFamily    = FontFamily.Default,
        fontWeight    = FontWeight.Normal,
        fontSize      = 14.sp,
        lineHeight    = 20.sp,
        letterSpacing = 0.25.sp
    ),
    labelSmall = TextStyle(
        fontFamily    = FontFamily.Default,
        fontWeight    = FontWeight.Medium,
        fontSize      = 11.sp,
        lineHeight    = 16.sp,
        letterSpacing = 0.5.sp
    )
)
