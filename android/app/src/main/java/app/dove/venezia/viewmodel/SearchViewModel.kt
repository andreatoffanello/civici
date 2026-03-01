package app.dove.venezia.viewmodel

import android.app.Application
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

    val query: StateFlow<String> = _query.asStateFlow()

    @OptIn(ExperimentalCoroutinesApi::class)
    val uiState: StateFlow<SearchUiState> = combine(_isLoading, _allNumbers, _query) { loading, numbers, q ->
        when {
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
        _isLoading.value = true
        viewModelScope.launch {
            val numbers = repository.getNumbers(code)
                .sortedWith(compareBy { it.toIntOrNull() ?: Int.MAX_VALUE })
            _allNumbers.value = numbers
            _isLoading.value = false
        }
    }

    fun setQuery(q: String) {
        _query.value = q.filter { it.isDigit() }
    }

    suspend fun getCoordinate(sestiereCode: String, numero: String): CivicoCoordinate? {
        return repository.getCoordinate(sestiereCode, numero)
    }
}
