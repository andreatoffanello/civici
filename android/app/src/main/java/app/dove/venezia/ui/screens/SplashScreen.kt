package app.dove.venezia.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.dove.venezia.R
import app.dove.venezia.ui.theme.VeneziaPrimary
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(onFinished: () -> Unit) {
    val alpha = remember { Animatable(0f) }

    LaunchedEffect(Unit) {
        alpha.animateTo(1f, animationSpec = tween(700))
        delay(1000)
        alpha.animateTo(0f, animationSpec = tween(400))
        onFinished()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(VeneziaPrimary),
        contentAlignment = Alignment.Center
    ) {
        // Logo bianco (lettere bianche su trasparente) centrato su sfondo rosso veneziano
        Image(
            painter = painterResource(R.drawable.logo_dove_white),
            contentDescription = "DoVe",
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .size(220.dp)
                .alpha(alpha.value)
        )
    }
}
