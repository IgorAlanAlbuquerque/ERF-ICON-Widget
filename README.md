# ERF-ICON-Widget

This repository builds the **ERF UI** Scaleform widget (`ERF_UI.swf`) used by the Elemental Reactions Framework (ERF) for Skyrim.
It renders circular gauges and per-reaction **icons** driven by ERF’s C++/Papyrus side.

### What this repo contains
- **ActionScript 2** UI code (`swf/as2`), including `ERF_Gauge.as` and `Register.as`
- **Icon registry JSONs** (e.g., `swf/registry/erf_core.json`)
- **XML template** for swfmill (`swf/template/gauge_template.xml`)
- **SWF build scripts**
  - `swf/build/generate_xml.py` → generates `dist/ERF_UI.generated.xml`
  - `tools/validate_registry.py` → validates icon registries
- **Bundled MTASC**: `tools/mtasc/` (contains `mtasc` binary + `std` headers)

---

## Building

### CI (GitHub Actions)
Every push/PR to `main`/`master` runs:
1. Validate registries  
   `python3 tools/validate_registry.py`
2. Generate asset XML  
   `python3 swf/build/generate_xml.py`
3. Bake base SWF with assets  
   `swfmill simple dist/ERF_UI.generated.xml dist/ERF_UI.pre.swf`
4. Inject AS2 via MTASC  
   `tools/mtasc/mtasc -version 8 -swf dist/ERF_UI.pre.swf -cp swf/as2 -main Register -frame 1 -out dist/ERF_UI.swf`
5. Upload artifact: `url in the end of the job`

### Local build
Requirements:
- `python3`
- `swfmill` in PATH
- MTASC needed (we bundle the linux version)

Commands (from repo root):
```bash
python3 tools/validate_registry.py
python3 swf/build/generate_xml.py

# Base SWF with assets
swfmill simple dist/ERF_UI.generated.xml dist/ERF_UI.pre.swf

# Inject ActionScript
chmod +x tools/mtasc/mtasc
tools/mtasc/mtasc \
  -version 8 \
  -swf dist/ERF_UI.pre.swf \
  -cp swf/as2 \
  -main Register \
  -frame 1 \
  -out dist/ERF_UI.swf
```

## How icons work

### Registry JSONs
Each registry JSON declares a **namespace** and a list of icons with `file` and `linkage`. Example:
```json
{
  "namespace": "erf_core",
  "icons": [
    { "file": "icons/erf_core/fire.png",  "linkage": "ERF_ICON__erf_core__fire"  },
    { "file": "icons/erf_core/frost.png", "linkage": "ERF_ICON__erf_core__frost" },
    { "file": "icons/erf_core/shock.png", "linkage": "ERF_ICON__erf_core__shock" }
  ]
}
```

The build embeds each PNG as a SWF library symbol with the given **linkage**.

## Linkage format
`ERF_ICON__<namespace>__<basename>` — where `<basename>` is the image file name without extension.  
**Examples:** `ERF_ICON__erf_core__fire`, `ERF_ICON__erf_core__frost`, `ERF_ICON__erf_core__shock`.

## Runtime usage (C++)
Reactions in ERF can reference an **icon linkage**. The HUD forwards that to the SWF and the AS2 attaches the symbol into the corresponding gauge slot.

```cpp
ERF_ReactionDesc_Public r{};
r.name = "Solo_Fire_85";
r.elements = &fire; r.elementCount = 1;
r.minPctEach = 0.85f;
r.hudTint = 0xF04A3A;
r.iconName = "ERF_ICON__erf_core__fire"; // must match the SWF linkage
api->RegisterReaction(r);
```

## AS2 API

The widget expects 8 parameters:

```as
setAll(
  comboRemain01:Array,     // [0..1] per active reaction (max 3)
  comboTints:Array,        // RGB for those reactions
  accumValues:Array,       // accumulation (0..100) per element or one mixed gauge
  accumColors:Array,       // colors for accumulation segments
  iconLinkages:Array,      // per slot: combos first, then accum slots
  isSingle:Boolean,        // single: one gauge per value
  isHorin:Boolean,         // true=horizontal, false=vertical
  spacing:Number           // slot spacing
):Boolean
```