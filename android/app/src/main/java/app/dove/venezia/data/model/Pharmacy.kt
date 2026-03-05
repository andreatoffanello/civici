package app.dove.venezia.data.model

import androidx.compose.ui.graphics.Color
import java.time.LocalDate
import java.time.LocalTime

data class DayHours(
    val openHour: Int,
    val openMinute: Int,
    val closeHour: Int,
    val closeMinute: Int
) {
    val openFormatted: String get() = "%d:%02d".format(openHour, openMinute)
    val closeFormatted: String get() = "%d:%02d".format(closeHour, closeMinute)

    fun containsTime(hour: Int, minute: Int): Boolean {
        val current = hour * 60 + minute
        val open = openHour * 60 + openMinute
        val close = closeHour * 60 + closeMinute
        return current in open until close
    }
}

data class PharmacyHours(
    val weekday: DayHours?,
    val saturday: DayHours?,
    val sunday: DayHours?
)

data class Pharmacy(
    val id: String,
    val name: String,
    val address: String,
    val sestiereCode: String?,
    val zonaCode: String?,
    val phone: String,
    val lat: Double,
    val lng: Double,
    val hours: PharmacyHours,
    val turpiDates: List<String>
) {
    val areaName: String
        get() {
            sestiereCode?.let { code ->
                Sestiere.fromCode(code)?.let { return it.displayName }
            }
            zonaCode?.let { code ->
                ZonaNormale.fromCode(code)?.let { return it.displayName }
            }
            return ""
        }

    val areaColor: Color
        get() {
            sestiereCode?.let { code ->
                Sestiere.fromCode(code)?.let { return it.color }
            }
            zonaCode?.let { code ->
                ZonaNormale.fromCode(code)?.let { return it.color }
            }
            return Color.Gray
        }

    fun isOnDuty(date: LocalDate = LocalDate.now()): Boolean {
        return turpiDates.contains(date.toString())
    }

    fun isOpen(now: LocalTime = LocalTime.now(), today: LocalDate = LocalDate.now()): Boolean {
        // If on 24h duty, always open
        if (isOnDuty(today)) return true

        val daySlot = when (today.dayOfWeek.value) {
            6 -> hours.saturday    // Saturday
            7 -> hours.sunday      // Sunday
            else -> hours.weekday  // Mon-Fri
        }
        return daySlot?.containsTime(now.hour, now.minute) == true
    }

    fun todayHoursFormatted(today: LocalDate = LocalDate.now()): String? {
        if (isOnDuty(today)) return "24h (turno)"

        val daySlot = when (today.dayOfWeek.value) {
            6 -> hours.saturday
            7 -> hours.sunday
            else -> hours.weekday
        } ?: return null

        return "${daySlot.openFormatted} – ${daySlot.closeFormatted}"
    }
}
