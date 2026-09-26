# Circuitry motion reel

A 15 second, 1920×1080, 60fps motion piece for Circuitry. The rendered video is not kept in the repo; run `render.mjs` to produce `circuitry-reel.mp4`.
Everything is code: `reel.html` draws each frame on a canvas, and `audio.mjs`
synthesizes a 120bpm soundtrack cued to the picture.

| Time | Scene | What happens |
| --- | --- | --- |
| 0–2s | Signal | A heartbeat pulse bursts into PCB traces carrying data packets. The camera dives into the core. |
| 2–3.5s | Blueprint | The app's blueprint grid tilts into place under the words BUILD. TEST. DEBUG. |
| 3.5–7s | Logic | A gate draws itself, then morphs AND → OR → NAND → NOR → XNOR → XOR on the beat while its truth table runs live. |
| 7–10.5s | Build | The gate flies into a half-adder circuit. Switches toggle, signals travel the wires and the display shows 1 + 1 = 2 for Problem #13. The camera dives into the lit segment. |
| 10.5–12.5s | Scale | Glitch cuts through 21 challenges, 28 circuit elements and the playground, then everything spirals into a single point. |
| 12.5–15s | Circuitry | The icon springs in, a signal pulses through the logo and the wordmark lands. |

Open `reel.html` in a browser to preview it in real time. To render the MP4, you
need Playwright and an ffmpeg with libx264:

```sh
node render.mjs                  # frames/ -> audio.wav -> circuitry-reel.mp4
node render.mjs --stills 4.2,9.8 # single frames to stills/
```

Each frame blends 4 sub-frames for motion blur. It also gets a bloom pass,
chromatic aberration and slice glitches on the cuts, a vignette, and film grain.
Fonts (Space Grotesk and JetBrains Mono, SIL OFL) are downloaded on first render.
