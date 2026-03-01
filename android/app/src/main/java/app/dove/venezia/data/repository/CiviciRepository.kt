package app.dove.venezia.data.repository

import android.content.Context
import app.dove.venezia.data.model.CivicoCoordinate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

class CiviciRepository(private val context: Context) {

    private val json = Json { ignoreUnknownKeys = true }
    private val mutex = Mutex()

    // Struttura: { "CN": { "18": { lat, lng }, ... }, ... }
    private var data: Map<String, Map<String, CivicoCoordinate>>? = null

    private suspend fun ensureLoaded(): Map<String, Map<String, CivicoCoordinate>> {
        return mutex.withLock {
            data ?: withContext(Dispatchers.IO) {
                val text = context.assets.open("civici.json").bufferedReader().readText()
                val parsed = json.decodeFromString<Map<String, Map<String, CivicoCoordinate>>>(text)
                data = parsed
                parsed
            }
        }
    }

    suspend fun getNumbers(sestiereCode: String): List<String> {
        return ensureLoaded()[sestiereCode]?.keys?.toList() ?: emptyList()
    }

    suspend fun getCoordinate(sestiereCode: String, numero: String): CivicoCoordinate? {
        return ensureLoaded()[sestiereCode]?.get(numero)
    }

    suspend fun getAllCodes(): Set<String> {
        return ensureLoaded().keys
    }
}
