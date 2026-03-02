package app.dove.venezia.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

enum class AppTheme    { SYSTEM, LIGHT, DARK }
enum class AppLanguage { SYSTEM, ITALIAN, ENGLISH }

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "dove_settings")

/**
 * Singleton per le preferenze app (tema + lingua).
 * Usa DataStore (sostituto moderno di SharedPreferences).
 * Va inizializzato una volta sola in MainActivity con [init].
 */
object AppPrefs {

    private val THEME_KEY    = stringPreferencesKey("theme")
    private val LANGUAGE_KEY = stringPreferencesKey("language")

    private lateinit var dataStore: DataStore<Preferences>
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val _theme    = MutableStateFlow(AppTheme.LIGHT)
    private val _language = MutableStateFlow(AppLanguage.SYSTEM)

    val theme:    StateFlow<AppTheme>    = _theme.asStateFlow()
    val language: StateFlow<AppLanguage> = _language.asStateFlow()

    fun init(context: Context) {
        dataStore = context.dataStore
        scope.launch {
            dataStore.data.map { prefs ->
                val t = try { AppTheme.valueOf(prefs[THEME_KEY] ?: AppTheme.LIGHT.name) }
                        catch (_: Exception) { AppTheme.LIGHT }
                val l = try { AppLanguage.valueOf(prefs[LANGUAGE_KEY] ?: AppLanguage.SYSTEM.name) }
                        catch (_: Exception) { AppLanguage.SYSTEM }
                t to l
            }.collect { (t, l) ->
                _theme.value    = t
                _language.value = l
            }
        }
    }

    fun setTheme(t: AppTheme) {
        _theme.value = t
        scope.launch {
            dataStore.edit { prefs -> prefs[THEME_KEY] = t.name }
        }
    }

    fun setLanguage(l: AppLanguage) {
        _language.value = l
        scope.launch {
            dataStore.edit { prefs -> prefs[LANGUAGE_KEY] = l.name }
        }
    }
}
