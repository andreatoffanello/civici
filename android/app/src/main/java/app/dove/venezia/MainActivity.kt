package app.dove.venezia

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import android.os.LocaleList
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import app.dove.venezia.data.AppLanguage
import app.dove.venezia.data.AppPrefs
import app.dove.venezia.data.AppTheme
import app.dove.venezia.ui.navigation.NavRoutes
import app.dove.venezia.ui.screens.InfoScreen
import app.dove.venezia.ui.screens.ResultScreen
import app.dove.venezia.ui.screens.SearchScreen
import app.dove.venezia.ui.screens.SestieriScreen
import app.dove.venezia.ui.screens.SettingsScreen
import app.dove.venezia.ui.screens.SplashScreen
import app.dove.venezia.ui.screens.StreetListScreen
import app.dove.venezia.ui.screens.StreetNumbersScreen
import app.dove.venezia.ui.theme.DoVeTheme
import app.dove.venezia.viewmodel.SearchViewModel
import app.dove.venezia.viewmodel.ZonaNormaleViewModel
import java.net.URLDecoder

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppPrefs.init(applicationContext)

        // Ripristina la locale salvata dall'utente
        val savedLang = AppPrefs.language.value
        if (savedLang != AppLanguage.SYSTEM) {
            val tag = when (savedLang) {
                AppLanguage.ITALIAN -> "it"
                AppLanguage.ENGLISH -> "en"
                else -> ""
            }
            AppCompatDelegate.setApplicationLocales(
                LocaleListCompat.forLanguageTags(tag)
            )
        }

        enableEdgeToEdge()
        setContent {
            val theme        by AppPrefs.theme.collectAsState()
            val systemIsDark = isSystemInDarkTheme()
            val isDark = when (theme) {
                AppTheme.DARK   -> true
                AppTheme.LIGHT  -> false
                AppTheme.SYSTEM -> systemIsDark
            }

            DoVeTheme(darkTheme = isDark) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    val navController        = rememberNavController()
                    val searchViewModel      : SearchViewModel      = viewModel()
                    val zonaNormaleViewModel : ZonaNormaleViewModel = viewModel()

                    NavHost(
                        navController    = navController,
                        startDestination = NavRoutes.SPLASH
                    ) {
                        // ── Splash ────────────────────────────────────────────
                        composable(NavRoutes.SPLASH) {
                            SplashScreen(
                                onFinished = {
                                    navController.navigate(NavRoutes.SESTIERI) {
                                        popUpTo(NavRoutes.SPLASH) { inclusive = true }
                                    }
                                }
                            )
                        }

                        // ── Sestieri / zone ───────────────────────────────────
                        composable(NavRoutes.SESTIERI) {
                            SestieriScreen(
                                onSestiereSelected = { code ->
                                    navController.navigate(NavRoutes.search(code))
                                },
                                onZonaSelected  = { code ->
                                    navController.navigate(NavRoutes.streetList(code))
                                },
                                onInfoClick     = { navController.navigate(NavRoutes.INFO) },
                                onSettingsClick = { navController.navigate(NavRoutes.SETTINGS) }
                            )
                        }

                        // ── Ricerca civico (sestieri) ─────────────────────────
                        composable(
                            route     = NavRoutes.SEARCH,
                            arguments = listOf(navArgument("sestiereCode") { type = NavType.StringType })
                        ) { backStack ->
                            val code = backStack.arguments?.getString("sestiereCode") ?: return@composable
                            SearchScreen(
                                sestiereCode  = code,
                                viewModel     = searchViewModel,
                                onCivicoClick = { numero, lat, lng ->
                                    navController.navigate(NavRoutes.result(code, numero, lat, lng))
                                },
                                onBack        = { navController.popBackStack() }
                            )
                        }

                        // ── Lista strade (zone normali) ───────────────────────
                        composable(
                            route     = NavRoutes.STREET_LIST,
                            arguments = listOf(navArgument("zonaCode") { type = NavType.StringType })
                        ) { backStack ->
                            val code = backStack.arguments?.getString("zonaCode") ?: return@composable
                            StreetListScreen(
                                zonaCode      = code,
                                viewModel     = zonaNormaleViewModel,
                                onStreetClick = { street ->
                                    navController.navigate(NavRoutes.streetNumbers(code, street))
                                },
                                onBack        = { navController.popBackStack() }
                            )
                        }

                        // ── Numeri civici per strada ──────────────────────────
                        composable(
                            route     = NavRoutes.STREET_NUMBERS,
                            arguments = listOf(
                                navArgument("zonaCode") { type = NavType.StringType },
                                navArgument("street")   { type = NavType.StringType }
                            )
                        ) { backStack ->
                            val code   = backStack.arguments?.getString("zonaCode") ?: return@composable
                            val street = URLDecoder.decode(
                                backStack.arguments?.getString("street") ?: return@composable, "UTF-8")
                            StreetNumbersScreen(
                                zonaCode      = code,
                                street        = street,
                                viewModel     = zonaNormaleViewModel,
                                onCivicoClick = { numero, lat, lng, via ->
                                    navController.navigate(NavRoutes.resultVia(code, numero, lat, lng, via))
                                },
                                onBack        = { navController.popBackStack() }
                            )
                        }

                        // ── Risultato (sestieri) ──────────────────────────────
                        composable(
                            route     = NavRoutes.RESULT,
                            arguments = listOf(
                                navArgument("sestiereCode") { type = NavType.StringType },
                                navArgument("numero")       { type = NavType.StringType },
                                navArgument("lat")          { type = NavType.StringType },
                                navArgument("lng")          { type = NavType.StringType }
                            )
                        ) { backStack ->
                            val code   = backStack.arguments?.getString("sestiereCode") ?: return@composable
                            val numero = backStack.arguments?.getString("numero")        ?: return@composable
                            val lat    = backStack.arguments?.getString("lat")?.toDoubleOrNull() ?: return@composable
                            val lng    = backStack.arguments?.getString("lng")?.toDoubleOrNull() ?: return@composable
                            ResultScreen(
                                sestiereCode = code,
                                numero       = numero,
                                lat          = lat,
                                lng          = lng,
                                onBack       = { navController.popBackStack() }
                            )
                        }

                        // ── Risultato con via (zone normali) ──────────────────
                        composable(
                            route     = NavRoutes.RESULT_VIA,
                            arguments = listOf(
                                navArgument("sestiereCode") { type = NavType.StringType },
                                navArgument("numero")       { type = NavType.StringType },
                                navArgument("lat")          { type = NavType.StringType },
                                navArgument("lng")          { type = NavType.StringType },
                                navArgument("via")          { type = NavType.StringType }
                            )
                        ) { backStack ->
                            val code   = backStack.arguments?.getString("sestiereCode") ?: return@composable
                            val numero = backStack.arguments?.getString("numero")        ?: return@composable
                            val lat    = backStack.arguments?.getString("lat")?.toDoubleOrNull() ?: return@composable
                            val lng    = backStack.arguments?.getString("lng")?.toDoubleOrNull() ?: return@composable
                            val via    = URLDecoder.decode(
                                backStack.arguments?.getString("via") ?: "", "UTF-8")
                            ResultScreen(
                                sestiereCode = code,
                                numero       = numero,
                                lat          = lat,
                                lng          = lng,
                                via          = via.ifBlank { null },
                                onBack       = { navController.popBackStack() }
                            )
                        }

                        // ── Info / Settings ───────────────────────────────────
                        composable(NavRoutes.INFO) {
                            InfoScreen(onBack = { navController.popBackStack() })
                        }
                        composable(NavRoutes.SETTINGS) {
                            SettingsScreen(onBack = { navController.popBackStack() })
                        }
                    }
                }
            }
        }
    }
}
