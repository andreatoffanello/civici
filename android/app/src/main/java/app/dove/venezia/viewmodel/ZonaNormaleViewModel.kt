package app.dove.venezia.viewmodel

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.dove.venezia.data.model.CivicoCoordinate
import app.dove.venezia.data.repository.ZonaNormaleRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface ZonaNormaleUiState {
    data object Loading : ZonaNormaleUiState
    data class  Ready(val items: List<String>) : ZonaNormaleUiState
    data object Error : ZonaNormaleUiState
}

class ZonaNormaleViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = ZonaNormaleRepository(application)

    private val _isLoading  = MutableStateFlow(false)
    private val _allItems   = MutableStateFlow<List<String>>(emptyList())
    private val _query      = MutableStateFlow("")
    private val _hasError   = MutableStateFlow(false)

    val query: StateFlow<String> = _query.asStateFlow()

    val uiState: StateFlow<ZonaNormaleUiState> =
        combine(_isLoading, _allItems, _query, _hasError) { loading, items, q, error ->
            when {
                error   -> ZonaNormaleUiState.Error
                loading -> ZonaNormaleUiState.Loading
                else -> {
                    val filtered = if (q.isEmpty()) items
                                   else items.filter { it.contains(q, ignoreCase = true) }
                    ZonaNormaleUiState.Ready(filtered)
                }
            }
        }.stateIn(
            scope          = viewModelScope,
            started        = SharingStarted.WhileSubscribed(5_000),
            initialValue   = ZonaNormaleUiState.Loading
        )

    fun loadStreets(zonaCode: String) {
        _query.value    = ""
        _hasError.value  = false
        _isLoading.value = true
        viewModelScope.launch {
            try {
                _allItems.value  = repository.getStreets(zonaCode)
            } catch (e: Exception) {
                Log.e("ZonaNormaleVM", "Errore caricamento strade per $zonaCode", e)
                _hasError.value = true
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadNumbers(zonaCode: String, street: String) {
        _query.value    = ""
        _hasError.value  = false
        _isLoading.value = true
        viewModelScope.launch {
            try {
                _allItems.value  = repository.getNumbers(zonaCode, street)
            } catch (e: Exception) {
                Log.e("ZonaNormaleVM", "Errore caricamento numeri per $zonaCode/$street", e)
                _hasError.value = true
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun setQuery(q: String) { _query.value = q }

    suspend fun getCoordinate(zonaCode: String, street: String, numero: String): CivicoCoordinate? =
        try {
            repository.getCoordinate(zonaCode, street, numero)
        } catch (e: Exception) {
            Log.e("ZonaNormaleVM", "Errore getCoordinate $zonaCode/$street/$numero", e)
            null
        }
}
