# madmom_beats_port_wasm

WASM wrapper around `madmom_beats_port_core`.

## Build

```bash
sh build_pkg.sh
```

This runs `wasm-pack build --target web`, copies `LICENSE` and `NOTICE` into
the generated `pkg/` distribution, and includes them in the package file
allowlist.

## Exported functions

- `default_config_json()`
- `validate_config_json(configJson?)`
- `analyze_json(samples, sampleRate, configJson?)`
- `analyze_json_with_model(samples, sampleRate, configJson?, modelJson, weightsNpz)`
- `analyze_json_with_model_progress(samples, sampleRate, configJson?, modelJson, weightsNpz, progressCb)`

Versioned JSON schemas:

- `docs/schemas/config.v1.schema.json`
- `docs/schemas/analysis-output.v1.schema.json`
- `docs/schemas/config.v1.example.json`

All functions return beat arrays:

```json
{
  "fps": 100,
  "beat_times": [0.2059, 0.645, 1.0222],
  "beat_numbers": [1, 2, 3],
  "beat_confidences": [0.83, 0.79, 0.81]
}
```

Output invariants:

- `beat_times`, `beat_numbers`, `beat_confidences` have the same length
- `beat_times` are strictly increasing
- `beat_numbers` are 1-based beat positions in bar
- `beat_confidences` are clamped to `[0, 1]`

`validate_config_json(configJson?)` returns:

- `null` on success
- error object on failure:
  - `code`: `CONFIG_PARSE_ERROR` or `CONFIG_VALIDATION_ERROR`
  - `message`
  - `path` (if known)
  - `context` (line/column for parse errors)

## Model assets

The WASM build does not embed model files. Provide:

- `models/downbeats_blstm.json`
- `models/downbeats_blstm_weights.npz` (binary data)

Use `analyze_json_with_model*` and pass the model JSON string and NPZ bytes.

## Worker usage (minimal)

```js
import init, {
  analyze_json_with_model_progress,
  default_config_json,
  validate_config_json,
} from "./madmom_beats_port_wasm.js";

await init();
const modelJson = await (await fetch("./models/downbeats_blstm.json")).text();
const weightsNpz = new Uint8Array(
  await (await fetch("./models/downbeats_blstm_weights.npz")).arrayBuffer(),
);
const defaultConfig = default_config_json();
const maybeValidationError = validate_config_json(defaultConfig);
if (maybeValidationError !== null) {
  throw new Error(JSON.stringify(maybeValidationError));
}

const result = analyze_json_with_model_progress(
  samples,
  44100,
  defaultConfig,
  modelJson,
  weightsNpz,
  (stage, progress) => postMessage({ stage, progress }),
);
postMessage({ result });
```

Progress stage IDs:

- `0`: features
- `1`: inference
- `2`: DBN decode

Cancellation:

- No explicit cancellation API yet.
- Run analysis in a Web Worker and terminate/replace the worker for cancellation.

## Licensing / redistribution

When you distribute the generated `pkg/` (the `.wasm` + JS glue), include
`LICENSE` and `NOTICE`. The helper script above copies both files into `pkg/`.
The source code is BSD 2-Clause and the core is a port of madmom, so binary
redistributions must reproduce the upstream madmom copyright notice.

If you distribute model files alongside `pkg/`, also include
`LICENSES/MODELS_CC_BY_NC_SA.txt` from the repo root and mark that
model-bearing distribution as CC BY-NC-SA 4.0 / non-commercial.
