package app.dove.venezia.data.model

import androidx.compose.ui.graphics.Color
import app.dove.venezia.ui.theme.Zona_Burano
import app.dove.venezia.ui.theme.Zona_Certosa
import app.dove.venezia.ui.theme.Zona_Lido
import app.dove.venezia.ui.theme.Zona_Mazzorbo
import app.dove.venezia.ui.theme.Zona_Murano
import app.dove.venezia.ui.theme.Zona_Pellestrina
import app.dove.venezia.ui.theme.Zona_SaccaFisola
import app.dove.venezia.ui.theme.Zona_SantElena
import app.dove.venezia.ui.theme.Zona_SantErasmo
import app.dove.venezia.ui.theme.Zona_Torcello
import app.dove.venezia.ui.theme.Zona_Vignole

enum class ZonaNormale(val code: String) {
    MURANO("MU"),
    BURANO("BU"),
    TORCELLO("TO"),
    MAZZORBO("MZ"),
    LIDO("LI"),
    PELLESTRINA("PE"),
    SANT_ERASMO("SR"),
    VIGNOLE("VI"),
    CERTOSA("CE"),
    SANT_ELENA("SE"),
    SACCA_FISOLA("SF");

    val displayName: String get() = when (this) {
        MURANO       -> "Murano"
        BURANO       -> "Burano"
        TORCELLO     -> "Torcello"
        MAZZORBO     -> "Mazzorbo"
        LIDO         -> "Lido"
        PELLESTRINA  -> "Pellestrina"
        SANT_ERASMO  -> "Sant\u2019Erasmo"
        VIGNOLE      -> "Vignole"
        CERTOSA      -> "Certosa"
        SANT_ELENA   -> "Sant\u2019Elena"
        SACCA_FISOLA -> "Sacca Fisola"
    }

    val color: Color get() = when (this) {
        MURANO       -> Zona_Murano
        BURANO       -> Zona_Burano
        TORCELLO     -> Zona_Torcello
        MAZZORBO     -> Zona_Mazzorbo
        LIDO         -> Zona_Lido
        PELLESTRINA  -> Zona_Pellestrina
        SANT_ERASMO  -> Zona_SantErasmo
        VIGNOLE      -> Zona_Vignole
        CERTOSA      -> Zona_Certosa
        SANT_ELENA   -> Zona_SantElena
        SACCA_FISOLA -> Zona_SaccaFisola
    }

    val lat: Double get() = when (this) {
        MURANO       -> 45.4585
        BURANO       -> 45.4855
        TORCELLO     -> 45.4970
        MAZZORBO     -> 45.4880
        LIDO         -> 45.4050
        PELLESTRINA  -> 45.3200
        SANT_ERASMO  -> 45.4780
        VIGNOLE      -> 45.4480
        CERTOSA      -> 45.4400
        SANT_ELENA   -> 45.4275
        SACCA_FISOLA -> 45.4260
    }

    val lng: Double get() = when (this) {
        MURANO       -> 12.3520
        BURANO       -> 12.4170
        TORCELLO     -> 12.4180
        MAZZORBO     -> 12.4080
        LIDO         -> 12.3600
        PELLESTRINA  -> 12.3100
        SANT_ERASMO  -> 12.4150
        VIGNOLE      -> 12.3800
        CERTOSA      -> 12.3680
        SANT_ELENA   -> 12.3630
        SACCA_FISOLA -> 12.3130
    }

    companion object {
        /** Isole della laguna */
        val isole = listOf(MURANO, BURANO, TORCELLO, MAZZORBO, LIDO, PELLESTRINA, SANT_ERASMO, VIGNOLE, CERTOSA)

        /** Zone del centro storico con indirizzamento stradale */
        val zoneCentro = listOf(SANT_ELENA, SACCA_FISOLA)

        fun fromCode(code: String): ZonaNormale? = entries.find { it.code == code }
    }
}
