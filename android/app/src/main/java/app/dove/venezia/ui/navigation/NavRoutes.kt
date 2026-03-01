package app.dove.venezia.ui.navigation

import java.net.URLEncoder

object NavRoutes {
    const val SPLASH    = "splash"
    const val SESTIERI  = "sestieri"

    // Ricerca sestiere — argomento: codice sestiere (es. "CN")
    const val SEARCH = "search/{sestiereCode}"
    fun search(code: String) = "search/$code"

    // Lista strade zona normale — argomento: codice zona (es. "LI")
    const val STREET_LIST = "street_list/{zonaCode}"
    fun streetList(code: String) = "street_list/$code"

    // Numeri civici per strada — argomenti: codice zona + nome strada (URL-encoded)
    const val STREET_NUMBERS = "street_numbers/{zonaCode}/{street}"
    fun streetNumbers(code: String, street: String) =
        "street_numbers/$code/${URLEncoder.encode(street, "UTF-8")}"

    // Risultato — sestiereCode può essere sestiere o zona; via opzionale per zone normali
    const val RESULT = "result/{sestiereCode}/{numero}/{lat}/{lng}"
    fun result(code: String, numero: String, lat: Double, lng: Double) =
        "result/$code/$numero/$lat/$lng"

    // Risultato con via (zone normali)
    const val RESULT_VIA = "result_via/{sestiereCode}/{numero}/{lat}/{lng}/{via}"
    fun resultVia(code: String, numero: String, lat: Double, lng: Double, via: String) =
        "result_via/$code/$numero/$lat/$lng/${URLEncoder.encode(via, "UTF-8")}"

    const val INFO      = "info"
    const val SETTINGS  = "settings"
}
