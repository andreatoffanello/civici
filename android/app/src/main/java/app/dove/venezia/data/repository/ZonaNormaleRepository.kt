package app.dove.venezia.data.repository

import android.content.Context
import app.dove.venezia.data.model.CivicoCoordinate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

// Struttura: { "LI": { "Via Roma": { "1": { lat, lng }, ... }, ... }, ... }
class ZonaNormaleRepository(private val context: Context) {

    private val json  = Json { ignoreUnknownKeys = true }
    private val mutex = Mutex()

    private var data: Map<String, Map<String, Map<String, CivicoCoordinate>>>? = null

    private suspend fun ensureLoaded(): Map<String, Map<String, Map<String, CivicoCoordinate>>> =
        mutex.withLock {
            data ?: withContext(Dispatchers.IO) {
                val text   = context.assets.open("zone_normali.json").bufferedReader().readText()
                val parsed = json.decodeFromString<Map<String, Map<String, Map<String, CivicoCoordinate>>>>(text)
                data = parsed
                parsed
            }
        }

    suspend fun getStreets(zonaCode: String): List<String> =
        ensureLoaded()[zonaCode]?.keys?.sorted() ?: emptyList()

    suspend fun getNumbers(zonaCode: String, street: String): List<String> =
        ensureLoaded()[zonaCode]?.get(street)?.keys?.toList()
            ?.sortedWith(compareBy { it.filter(Char::isDigit).toIntOrNull() ?: Int.MAX_VALUE })
            ?: emptyList()

    suspend fun getCoordinate(zonaCode: String, street: String, numero: String): CivicoCoordinate? =
        ensureLoaded()[zonaCode]?.get(street)?.get(numero)
}
