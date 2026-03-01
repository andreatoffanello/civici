package app.dove.venezia.data.model

import androidx.compose.ui.graphics.Color
import app.dove.venezia.ui.theme.Sestiere_Cannaregio
import app.dove.venezia.ui.theme.Sestiere_Castello
import app.dove.venezia.ui.theme.Sestiere_Dorsoduro
import app.dove.venezia.ui.theme.Sestiere_Giudecca
import app.dove.venezia.ui.theme.Sestiere_SanMarco
import app.dove.venezia.ui.theme.Sestiere_SanPolo
import app.dove.venezia.ui.theme.Sestiere_SantaCroce

enum class Sestiere(val code: String) {
    CANNAREGIO("CN"),
    CASTELLO("CS"),
    DORSODURO("DD"),
    GIUDECCA("GD"),
    SANTA_CROCE("SC"),
    SAN_MARCO("SM"),
    SAN_POLO("SP");

    val displayName: String get() = when (this) {
        CANNAREGIO  -> "Cannaregio"
        CASTELLO    -> "Castello"
        DORSODURO   -> "Dorsoduro"
        GIUDECCA    -> "Giudecca"
        SANTA_CROCE -> "Santa Croce"
        SAN_MARCO   -> "San Marco"
        SAN_POLO    -> "San Polo"
    }

    val color: Color get() = when (this) {
        CANNAREGIO  -> Sestiere_Cannaregio
        CASTELLO    -> Sestiere_Castello
        DORSODURO   -> Sestiere_Dorsoduro
        GIUDECCA    -> Sestiere_Giudecca
        SANTA_CROCE -> Sestiere_SantaCroce
        SAN_MARCO   -> Sestiere_SanMarco
        SAN_POLO    -> Sestiere_SanPolo
    }

    val lat: Double get() = when (this) {
        CANNAREGIO  -> 45.4435
        CASTELLO    -> 45.4333
        DORSODURO   -> 45.4308
        GIUDECCA    -> 45.4266
        SANTA_CROCE -> 45.4396
        SAN_MARCO   -> 45.4339
        SAN_POLO    -> 45.4375
    }

    val lng: Double get() = when (this) {
        CANNAREGIO  -> 12.3308
        CASTELLO    -> 12.3492
        DORSODURO   -> 12.3257
        GIUDECCA    -> 12.3253
        SANTA_CROCE -> 12.3271
        SAN_MARCO   -> 12.3341
        SAN_POLO    -> 12.3300
    }

    val numberRange: String get() = when (this) {
        CANNAREGIO  -> "1 – 6420"
        CASTELLO    -> "1 – 6828"
        DORSODURO   -> "1 – 3901"
        GIUDECCA    -> "1 – 907"
        SANTA_CROCE -> "1 – 2362"
        SAN_MARCO   -> "1 – 5562"
        SAN_POLO    -> "1 – 3144"
    }

    companion object {
        fun fromCode(code: String): Sestiere? = entries.find { it.code == code }
    }
}
