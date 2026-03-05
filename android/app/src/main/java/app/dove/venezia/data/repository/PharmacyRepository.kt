package app.dove.venezia.data.repository

import android.content.Context
import android.util.Log
import app.dove.venezia.data.model.DayHours
import app.dove.venezia.data.model.Pharmacy
import app.dove.venezia.data.model.PharmacyHours
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class PharmacyRepository(private val context: Context) {

    private val mutex = Mutex()
    private var pharmacies: List<Pharmacy>? = null

    companion object {
        private const val TAG = "PharmacyRepo"
        private const val REMOTE_URL = "https://andreatoffanello.github.io/civici/api/farmacie.json"
        private const val TIMEOUT_MS = 8_000
    }

    suspend fun getAll(): List<Pharmacy> {
        return mutex.withLock {
            pharmacies ?: withContext(Dispatchers.IO) {
                val parsed = fetchRemoteOrFallback()
                pharmacies = parsed
                parsed
            }
        }
    }

    private fun fetchRemoteOrFallback(): List<Pharmacy> {
        // Try remote first
        try {
            val conn = URL(REMOTE_URL).openConnection() as HttpURLConnection
            conn.connectTimeout = TIMEOUT_MS
            conn.readTimeout = TIMEOUT_MS
            conn.requestMethod = "GET"

            if (conn.responseCode == 200) {
                val text = conn.inputStream.bufferedReader().readText()
                val parsed = parseJson(text)
                if (parsed.isNotEmpty()) {
                    Log.d(TAG, "Loaded ${parsed.size} pharmacies from remote")
                    conn.disconnect()
                    return parsed
                }
            }
            conn.disconnect()
        } catch (e: Exception) {
            Log.w(TAG, "Remote fetch failed, using bundled data", e)
        }

        // Fallback to bundled
        val text = context.assets.open("farmacie.json").bufferedReader().readText()
        val parsed = parseJson(text)
        Log.d(TAG, "Loaded ${parsed.size} pharmacies from bundled data")
        return parsed
    }

    private fun parseJson(jsonText: String): List<Pharmacy> {
        // Support both wrapped format {"pharmacies": [...]} and plain array [...]
        val array = try {
            val root = JSONObject(jsonText)
            root.getJSONArray("pharmacies")
        } catch (_: Exception) {
            JSONArray(jsonText)
        }

        val list = mutableListOf<Pharmacy>()
        for (i in 0 until array.length()) {
            try {
                list.add(parsePharmacy(array.getJSONObject(i)))
            } catch (e: Exception) {
                Log.w(TAG, "Failed to parse pharmacy at index $i", e)
            }
        }
        return list
    }

    private fun parsePharmacy(obj: JSONObject): Pharmacy {
        val hours = if (obj.has("hours") && !obj.isNull("hours")) {
            parseHours(obj.getJSONObject("hours"))
        } else {
            PharmacyHours(null, null, null)
        }

        val turpiDates = if (obj.has("turpiDates") && !obj.isNull("turpiDates")) {
            val arr = obj.getJSONArray("turpiDates")
            (0 until arr.length()).map { arr.getString(it) }
        } else {
            emptyList()
        }

        return Pharmacy(
            id = obj.getString("id"),
            name = obj.getString("name"),
            address = obj.getString("address"),
            sestiereCode = if (obj.has("sestiereCode") && !obj.isNull("sestiereCode")) obj.getString("sestiereCode") else null,
            zonaCode = if (obj.has("zonaCode") && !obj.isNull("zonaCode")) obj.getString("zonaCode") else null,
            phone = obj.getString("phone"),
            lat = obj.getDouble("lat"),
            lng = obj.getDouble("lng"),
            hours = hours,
            turpiDates = turpiDates
        )
    }

    private fun parseHours(obj: JSONObject): PharmacyHours {
        return PharmacyHours(
            weekday = parseDayHours(obj.opt("weekday")),
            saturday = parseDayHours(obj.opt("saturday")),
            sunday = parseDayHours(obj.opt("sunday"))
        )
    }

    private fun parseDayHours(value: Any?): DayHours? {
        if (value == null || value == JSONObject.NULL) return null
        val obj = value as? JSONObject ?: return null
        if (!obj.has("open") || !obj.has("close")) return null
        val open = obj.getString("open")
        val close = obj.getString("close")

        val openParts = open.split(":").map { it.toIntOrNull() ?: 0 }
        val closeParts = close.split(":").map { it.toIntOrNull() ?: 0 }

        return DayHours(
            openHour = openParts.getOrElse(0) { 0 },
            openMinute = openParts.getOrElse(1) { 0 },
            closeHour = closeParts.getOrElse(0) { 0 },
            closeMinute = closeParts.getOrElse(1) { 0 }
        )
    }
}
