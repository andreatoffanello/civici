<template>
  <canvas
    ref="canvas"
    class="hero-canvas"
    @mousemove="onMouseMove"
    @mouseleave="onMouseLeave"
  />
</template>

<script setup>
const canvas = ref(null)

let gl = null
let program = null
let animFrame = null
let startTime = 0
let mouse = { x: 0.5, y: 0.5 }
let mouseTarget = { x: 0.5, y: 0.5 }
let dpr = 1

const VERTEX_SRC = `
  attribute vec2 aPosition;
  void main() {
    gl_Position = vec4(aPosition, 0.0, 1.0);
  }
`

const FRAGMENT_SRC = `
  precision highp float;
  uniform float uTime;
  uniform vec2 uResolution;
  uniform vec2 uMouse;

  // --- Noise functions ---
  vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
  vec2 mod289v2(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
  vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

  float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289v2(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m; m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
  }

  float fbm(vec2 p) {
    float f = 0.0;
    f += 0.5000 * snoise(p); p *= 2.01;
    f += 0.2500 * snoise(p); p *= 2.02;
    f += 0.1250 * snoise(p); p *= 2.03;
    f += 0.0625 * snoise(p);
    return f;
  }

  void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;
    float aspect = uResolution.x / uResolution.y;

    // Page background
    vec3 bg = vec3(0.980, 0.965, 0.945); // #FAF6F1

    float t = uTime * 0.12;

    // Mouse influence
    vec2 mouseUV = uMouse;
    vec2 diff = uv - mouseUV;
    diff.x *= aspect;
    float mouseDist = length(diff);
    float mouseInfluence = smoothstep(0.6, 0.0, mouseDist) * 0.12;

    // Noise coordinates
    vec2 noiseUV = uv * 1.8;
    noiseUV.x *= aspect;
    noiseUV += vec2(t * 0.4, t * 0.25);
    noiseUV += diff * mouseInfluence * 4.0;

    // Three layered noise fields
    float n1 = fbm(noiseUV);
    float n2 = fbm(noiseUV + vec2(5.2, 1.3) + t * 0.15);
    float n3 = fbm(noiseUV * 0.7 + vec2(n1, n2) * 0.4);

    // --- Color blobs ---
    // Each blob is a soft gradient circle, positioned with noise-driven movement
    vec2 p = vec2(uv.x * aspect, uv.y);

    // Blob 1 — terracotta/coral (top-right area)
    vec2 b1 = vec2(0.65 * aspect, 0.6);
    b1 += vec2(sin(t * 0.7) * 0.12, cos(t * 0.5) * 0.08);
    b1.x += snoise(vec2(t * 0.3, 1.0)) * 0.08;
    float d1 = length((p - b1) * vec2(0.8, 1.2));
    float blob1 = smoothstep(0.45, 0.0, d1);

    // Blob 2 — blue/teal (left area)
    vec2 b2 = vec2(0.3 * aspect, 0.45);
    b2 += vec2(cos(t * 0.6) * 0.1, sin(t * 0.8) * 0.1);
    b2.y += snoise(vec2(t * 0.25, 3.0)) * 0.06;
    float d2 = length((p - b2) * vec2(1.1, 0.85));
    float blob2 = smoothstep(0.4, 0.0, d2);

    // Blob 3 — gold/warm (bottom-center)
    vec2 b3 = vec2(0.5 * aspect, 0.3);
    b3 += vec2(sin(t * 0.45 + 2.0) * 0.15, cos(t * 0.55) * 0.06);
    float d3 = length((p - b3) * vec2(0.9, 1.3));
    float blob3 = smoothstep(0.38, 0.0, d3);

    // Blob 4 — lavender (top-left corner, subtle)
    vec2 b4 = vec2(0.25 * aspect, 0.72);
    b4 += vec2(cos(t * 0.5 + 1.0) * 0.08, sin(t * 0.4) * 0.06);
    float d4 = length((p - b4) * vec2(1.0, 1.0));
    float blob4 = smoothstep(0.32, 0.0, d4);

    // Blob 5 — sage green (right edge)
    vec2 b5 = vec2(0.75 * aspect, 0.35);
    b5 += vec2(sin(t * 0.35) * 0.06, cos(t * 0.65 + 1.5) * 0.1);
    float d5 = length((p - b5) * vec2(1.2, 0.9));
    float blob5 = smoothstep(0.35, 0.0, d5);

    // Blob colors — warm, venetian, desaturated for elegance
    vec3 col1 = vec3(0.82, 0.45, 0.35);  // terracotta
    vec3 col2 = vec3(0.45, 0.65, 0.78);  // blue
    vec3 col3 = vec3(0.85, 0.75, 0.45);  // gold
    vec3 col4 = vec3(0.68, 0.58, 0.78);  // lavender
    vec3 col5 = vec3(0.45, 0.72, 0.68);  // sage

    // Add noise-based shimmer to each blob
    blob1 *= 0.7 + 0.3 * (0.5 + 0.5 * snoise(noiseUV * 1.5 + vec2(0.0, t * 0.2)));
    blob2 *= 0.7 + 0.3 * (0.5 + 0.5 * snoise(noiseUV * 1.3 + vec2(2.0, t * 0.15)));
    blob3 *= 0.7 + 0.3 * (0.5 + 0.5 * snoise(noiseUV * 1.4 + vec2(4.0, t * 0.18)));
    blob4 *= 0.7 + 0.3 * (0.5 + 0.5 * snoise(noiseUV * 1.2 + vec2(6.0, t * 0.22)));
    blob5 *= 0.7 + 0.3 * (0.5 + 0.5 * snoise(noiseUV * 1.6 + vec2(8.0, t * 0.16)));

    // Composite blobs — additive blending with soft clamp
    vec3 blobs = vec3(0.0);
    blobs += col1 * blob1 * 0.55;
    blobs += col2 * blob2 * 0.50;
    blobs += col3 * blob3 * 0.45;
    blobs += col4 * blob4 * 0.40;
    blobs += col5 * blob5 * 0.42;

    float totalAlpha = blob1 * 0.55 + blob2 * 0.50 + blob3 * 0.45 + blob4 * 0.40 + blob5 * 0.42;
    totalAlpha = clamp(totalAlpha, 0.0, 1.0);

    // Mouse glow — adds brightness near cursor
    float glow = smoothstep(0.5, 0.0, mouseDist) * 0.15;
    totalAlpha = clamp(totalAlpha + glow, 0.0, 1.0);

    // Blend: where there are blobs, show the blob color; otherwise show bg
    vec3 blobColor = totalAlpha > 0.001 ? blobs / max(totalAlpha, 0.001) : bg;
    vec3 finalColor = mix(bg, blobColor, totalAlpha * 0.85);

    // Very soft edge fade — let edges breathe into background
    float edgeFade = 1.0;
    edgeFade *= smoothstep(0.0, 0.15, uv.x) * smoothstep(1.0, 0.85, uv.x);
    edgeFade *= smoothstep(0.0, 0.12, uv.y) * smoothstep(1.0, 0.88, uv.y);
    finalColor = mix(bg, finalColor, edgeFade);

    gl_FragColor = vec4(finalColor, 1.0);
  }
`

function onMouseMove(e) {
  const rect = canvas.value.getBoundingClientRect()
  mouseTarget.x = (e.clientX - rect.left) / rect.width
  mouseTarget.y = 1.0 - (e.clientY - rect.top) / rect.height
}

function onMouseLeave() {
  mouseTarget.x = 0.5
  mouseTarget.y = 0.5
}

function initGL() {
  const c = canvas.value
  if (!c) return

  dpr = Math.min(window.devicePixelRatio, 2)

  gl = c.getContext('webgl', { alpha: false, antialias: false })
  if (!gl) return

  // Compile shaders
  const vs = gl.createShader(gl.VERTEX_SHADER)
  gl.shaderSource(vs, VERTEX_SRC)
  gl.compileShader(vs)

  const fs = gl.createShader(gl.FRAGMENT_SHADER)
  gl.shaderSource(fs, FRAGMENT_SRC)
  gl.compileShader(fs)

  if (!gl.getShaderParameter(fs, gl.COMPILE_STATUS)) {
    console.error('Fragment shader error:', gl.getShaderInfoLog(fs))
    return
  }

  program = gl.createProgram()
  gl.attachShader(program, vs)
  gl.attachShader(program, fs)
  gl.linkProgram(program)
  gl.useProgram(program)

  // Full-screen quad
  const buf = gl.createBuffer()
  gl.bindBuffer(gl.ARRAY_BUFFER, buf)
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 1,-1, -1,1, 1,1]), gl.STATIC_DRAW)

  const aPos = gl.getAttribLocation(program, 'aPosition')
  gl.enableVertexAttribArray(aPos)
  gl.vertexAttribPointer(aPos, 2, gl.FLOAT, false, 0, 0)

  resize()
  startTime = performance.now()
  render()
}

function resize() {
  const c = canvas.value
  if (!c || !gl) return

  const rect = c.getBoundingClientRect()
  c.width = rect.width * dpr
  c.height = rect.height * dpr
  gl.viewport(0, 0, c.width, c.height)
}

function render() {
  if (!gl || !program) return

  // Smooth mouse
  mouse.x += (mouseTarget.x - mouse.x) * 0.05
  mouse.y += (mouseTarget.y - mouse.y) * 0.05

  const t = (performance.now() - startTime) / 1000

  gl.uniform1f(gl.getUniformLocation(program, 'uTime'), t)
  gl.uniform2f(gl.getUniformLocation(program, 'uResolution'), canvas.value.width, canvas.value.height)
  gl.uniform2f(gl.getUniformLocation(program, 'uMouse'), mouse.x, mouse.y)

  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)
  animFrame = requestAnimationFrame(render)
}

let resizeObserver = null

onMounted(() => {
  if (!import.meta.client) return
  initGL()

  resizeObserver = new ResizeObserver(() => resize())
  resizeObserver.observe(canvas.value)
})

onUnmounted(() => {
  if (animFrame) cancelAnimationFrame(animFrame)
  if (resizeObserver) resizeObserver.disconnect()
})
</script>

<style scoped>
.hero-canvas {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  z-index: 0;
}
</style>
