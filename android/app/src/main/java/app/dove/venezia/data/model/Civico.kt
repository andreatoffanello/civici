package app.dove.venezia.data.model

import kotlinx.serialization.Serializable

@Serializable
data class CivicoCoordinate(
    val lat: Double,
    val lng: Double
)

data class Civico(
    val sestiere: String,
    val numero: String,
    val lat: Double,
    val lng: Double
)
