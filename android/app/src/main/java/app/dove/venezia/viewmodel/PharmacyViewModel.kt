package app.dove.venezia.viewmodel

import android.app.Application
import android.location.Location
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.dove.venezia.data.model.Pharmacy
import app.dove.venezia.data.repository.PharmacyRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface PharmacyUiState {
    data object Loading : PharmacyUiState
    data class Ready(
        val open: List<PharmacyWithDistance>,
        val closed: List<PharmacyWithDistance>,
        val openCount: Int,
        val totalCount: Int
    ) : PharmacyUiState
    data object Error : PharmacyUiState
}

data class PharmacyWithDistance(
    val pharmacy: Pharmacy,
    val distanceMeters: Float?
) {
    val formattedDistance: String?
        get() {
            val d = distanceMeters ?: return null
            return if (d < 1000) "${d.toInt()} m" else "%.1f km".format(d / 1000f)
        }
}

class PharmacyViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = PharmacyRepository(application)

    private val _allPharmacies = MutableStateFlow<List<Pharmacy>>(emptyList())
    private val _isLoading = MutableStateFlow(false)
    private val _hasError = MutableStateFlow(false)
    private val _userLocation = MutableStateFlow<Location?>(null)

    val totalCount: StateFlow<Int> get() = _totalCount
    private val _totalCount = MutableStateFlow(0)

    val openCount: StateFlow<Int> get() = _openCount
    private val _openCount = MutableStateFlow(0)

    val uiState: StateFlow<PharmacyUiState> = combine(
        _isLoading, _allPharmacies, _hasError, _userLocation
    ) { loading, pharmacies, error, location ->
        when {
            error -> PharmacyUiState.Error
            loading -> PharmacyUiState.Loading
            else -> {
                val withDistance = pharmacies.map { pharmacy ->
                    val distance = location?.let { loc ->
                        val results = FloatArray(1)
                        Location.distanceBetween(
                            loc.latitude, loc.longitude,
                            pharmacy.lat, pharmacy.lng,
                            results
                        )
                        results[0]
                    }
                    PharmacyWithDistance(pharmacy, distance)
                }.let { list ->
                    if (location != null) list.sortedBy { it.distanceMeters ?: Float.MAX_VALUE }
                    else list
                }

                val open = withDistance.filter { it.pharmacy.isOpen() }
                val closed = withDistance.filter { !it.pharmacy.isOpen() }

                _totalCount.value = pharmacies.size
                _openCount.value = open.size

                PharmacyUiState.Ready(
                    open = open,
                    closed = closed,
                    openCount = open.size,
                    totalCount = pharmacies.size
                )
            }
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = PharmacyUiState.Loading
    )

    fun loadData() {
        if (_allPharmacies.value.isNotEmpty()) return
        _isLoading.value = true
        _hasError.value = false
        viewModelScope.launch {
            try {
                _allPharmacies.value = repository.getAll()
            } catch (e: Exception) {
                Log.e("PharmacyViewModel", "Error loading pharmacies", e)
                _hasError.value = true
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun updateLocation(location: Location?) {
        _userLocation.value = location
    }
}
