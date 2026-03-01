package app.dove.venezia

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import app.dove.venezia.ui.navigation.NavRoutes
import app.dove.venezia.ui.screens.InfoScreen
import app.dove.venezia.ui.screens.ResultScreen
import app.dove.venezia.ui.screens.SearchScreen
import app.dove.venezia.ui.screens.SestieriScreen
import app.dove.venezia.ui.screens.SettingsScreen
import app.dove.venezia.ui.screens.SplashScreen
import app.dove.venezia.ui.theme.DoVeTheme
import app.dove.venezia.viewmodel.SearchViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            DoVeTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    val navController = rememberNavController()
                    val searchViewModel: SearchViewModel = viewModel()

                    NavHost(
                        navController    = navController,
                        startDestination = NavRoutes.SPLASH
                    ) {
                        composable(NavRoutes.SPLASH) {
                            SplashScreen(
                                onFinished = {
                                    navController.navigate(NavRoutes.SESTIERI) {
                                        popUpTo(NavRoutes.SPLASH) { inclusive = true }
                                    }
                                }
                            )
                        }

                        composable(NavRoutes.SESTIERI) {
                            SestieriScreen(
                                onSestiereSelected = { code ->
                                    navController.navigate(NavRoutes.search(code))
                                },
                                onZonaSelected  = { code ->
                                    navController.navigate(NavRoutes.search(code))
                                },
                                onInfoClick     = { navController.navigate(NavRoutes.INFO) },
                                onSettingsClick = { navController.navigate(NavRoutes.SETTINGS) }
                            )
                        }

                        composable(
                            route = NavRoutes.SEARCH,
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

                        composable(
                            route = NavRoutes.RESULT,
                            arguments = listOf(
                                navArgument("sestiereCode") { type = NavType.StringType },
                                navArgument("numero")       { type = NavType.StringType },
                                navArgument("lat")          { type = NavType.StringType },
                                navArgument("lng")          { type = NavType.StringType }
                            )
                        ) { backStack ->
                            val code   = backStack.arguments?.getString("sestiereCode") ?: return@composable
                            val numero = backStack.arguments?.getString("numero") ?: return@composable
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
