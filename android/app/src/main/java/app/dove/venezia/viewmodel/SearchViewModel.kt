package app.dove.venezia.viewmodel

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.dove.venezia.data.model.CivicoCoordinate
import app.dove.venezia.data.repository.CiviciRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface SearchUiState {
    data object Loading : SearchUiState
    data class Ready(val numbers: List<String>) : SearchUiState
    data object Error : SearchUiState
}

class SearchViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = CiviciRepository(application)

    private val _currentSestiere = MutableStateFlow("")
    private val _query = MutableStateFlow("")
    private val _allNumbers = MutableStateFlow<List<String>>(emptyList())
    private val _isLoading = MutableStateFlow(false)
    private val _hasError  = MutableStateFlow(false)

    val query: StateFlow<String> = _query.asStateFlow()

    @OptIn(ExperimentalCoroutinesApi::class)
    val uiState: StateFlow<SearchUiState> = combine(_isLoading, _allNumbers, _query, _hasError) { loading, numbers, q, error ->
        when {
            error   -> SearchUiState.Error
            loading -> SearchUiState.Loading
            else -> {
                val filtered = if (q.isEmpty()) numbers
                               else numbers.filter { it.startsWith(q) }
                SearchUiState.Ready(filtered)
            }
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = SearchUiState.Loading
    )

    fun loadSestiere(code: String) {
        if (_currentSestiere.value == code && _allNumbers.value.isNotEmpty()) return
        _currentSestiere.value = code
        _query.value = ""
        _hasError.value = false
        _isLoading.value = true
        viewModelScope.launch {
            try {
                val numbers = repository.getNumbers(code)
                    .sortedWith(compareBy { it.toIntOrNull() ?: Int.MAX_VALUE })
                _allNumbers.value = numbers
            } catch (e: Exception) {
                Log.e("SearchViewModel", "Errore caricamento civici per $code", e)
                _hasError.value = true
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun setQuery(q: String) {
        _query.value = q.filter { it.isDigit() }
    }

    suspend fun getCoordinate(sestiereCode: String, numero: String): CivicoCoordinate? {
        return try {
            repository.getCoordinate(sestiereCode, numero)
        } catch (e: Exception) {
            Log.e("SearchViewModel", "Errore getCoordinate $sestiereCode/$numero", e)
            null
        }
    }
}
