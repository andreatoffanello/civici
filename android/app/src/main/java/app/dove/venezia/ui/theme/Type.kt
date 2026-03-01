package app.dove.venezia.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.dove.venezia.R

// Font Sotoportego — serif veneziano, usato per nomi sestieri e logo
// NOTA: in iOS era CCXLKSNizioleti-Regular, aggiornato a Sotoportego.otf
// che è il font serif elegante usato nell'app iOS definitiva
val SotoportegoFontFamily = FontFamily(
    Font(R.font.sotoportego, FontWeight.Normal)
)

// Alias per retrocompatibilità con codice che usa NizioletiFontFamily
val NizioletiFontFamily = SotoportegoFontFamily

val DoVeTypography = Typography(
    // Splash / logo DoVe grande
    displayLarge = TextStyle(
        fontFamily    = SotoportegoFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 72.sp,
        lineHeight    = 80.sp,
        letterSpacing = 4.sp
    ),
    // Numero civico nel risultato / heading principale
    headlineLarge = TextStyle(
        fontFamily  = SotoportegoFontFamily,
        fontWeight  = FontWeight.Normal,
        fontSize    = 36.sp,
        lineHeight  = 44.sp
    ),
    // Nome sestiere nella lista (grande, colorato)
    titleLarge = TextStyle(
        fontFamily    = SotoportegoFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 26.sp,
        lineHeight    = 32.sp,
        letterSpacing = 2.sp
    ),
    // Nome sestiere nella topbar / header sezione
    titleMedium = TextStyle(
        fontFamily    = SotoportegoFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 18.sp,
        lineHeight    = 24.sp,
        letterSpacing = 1.5.sp
    ),
    // Numero civico nella pill (bold, terracotta)
    bodyLarge = TextStyle(
        fontFamily    = SotoportegoFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 17.sp,
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
