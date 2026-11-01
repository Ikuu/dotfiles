// Diagonal gradient on the focused window's border, from accent_primary at the
// bottom left to accent_secondary at the top right. The palette wraps over
// [0, 1): accent_primary 0.0, accent_secondary 0.25, warning 0.5, error 0.75.
// The native ring's alpha keeps its shape and antialiased edges.
vec4 border(vec2 uv) {
  float ring = umbriel_sample(uv).a;
  float t = (uv.x + 1.0 - uv.y) * 0.5;
  return mix(umbriel_palette_at(0.0), umbriel_palette_at(0.25), t) * ring;
}
