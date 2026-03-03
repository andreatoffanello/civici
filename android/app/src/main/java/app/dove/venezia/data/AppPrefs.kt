package app.dove.venezia.data

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class AppTheme    { SYSTEM, LIGHT, DARK }
enum class AppLanguage { SYSTEM, ITALIAN, ENGLISH }

/**
 * Singleton per le preferenze app (tema + lingua).
 * Va inizializzato una volta sola in MainActivity con [init].
 */
object AppPrefs {

    private var prefs: SharedPreferences? = null

    private val _theme    = MutableStateFlow(AppTheme.LIGHT)
    private val _language = MutableStateFlow(AppLanguage.SYSTEM)

    val theme:    StateFlow<AppTheme>    = _theme.asStateFlow()
    val language: StateFlow<AppLanguage> = _language.asStateFlow()

    fun init(context: Context) {
        prefs = context.getSharedPreferences("dove_settings", Context.MODE_PRIVATE)
        _theme.value    = AppTheme.valueOf(
            prefs!!.getString("theme", AppTheme.LIGHT.name) ?: AppTheme.LIGHT.name)
        _language.value = AppLanguage.valueOf(
            prefs!!.getString("language", AppLanguage.SYSTEM.name) ?: AppLanguage.SYSTEM.name)
    }

    fun setTheme(t: AppTheme) {
        _theme.value = t
        prefs?.edit()?.putString("theme", t.name)?.apply()
    }

    fun setLanguage(l: AppLanguage) {
        _language.value = l
        prefs?.edit()?.putString("language", l.name)?.apply()
    }
}
