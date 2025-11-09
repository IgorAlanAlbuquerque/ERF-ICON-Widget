# LINKAGE_CONVENTION.md

## Purpose
This document defines the **linkage naming** used for icons exported into the SWF. A stable, predictable linkage lets native code reference icons safely.

---

## Linkage format
`ERF_ICON__<namespace>__<basename>`

- **Prefix:** `ERF_ICON__` (constant)
- **`<namespace>`:** logical pack (e.g., `erf_core`)
- **`<basename>`:** image file name without extension (e.g., `fire`)

### Examples
- `icons/erf_core/fire.png`  → `ERF_ICON__erf_core__fire`
- `icons/erf_core/frost.png` → `ERF_ICON__erf_core__frost`
- `icons/erf_core/shock.png` → `ERF_ICON__erf_core__shock`

---

## Rules
- **Uniqueness:** each linkage must be unique across all registries.
- **Characters:** use `a–z`, `0–9`, and `_` for both namespace and basename.  
  *(Lowercase recommended; avoid spaces and special characters.)*
- **Extension is excluded:** `.png` is not part of the linkage.
- **Case sensitivity:** treated as case-sensitive in code; stick to lowercase to avoid surprises.

---

## Where linkages are defined
In registry JSON files under `swf/registry/`. Schema:
```json
{
  "namespace": "erf_core",
  "icons": [
    { "file": "icons/erf_core/fire.png", "linkage": "ERF_ICON__erf_core__fire" }
  ]
}
```

file: path to the PNG in the repo

linkage: must follow the format above

The build step (generate_xml.py) reads all registries and emits a single dist/ERF_UI.generated.xml, which swfmill compiles into symbols inside the SWF.

## Using linkages in native code

Use the exact linkage string when registering reactions:

```cpp
ERF_ReactionDesc_Public r{};
r.name = "Solo_Fire_85";
r.elements = &fire; r.elementCount = 1;
r.minPctEach = 0.85f;
r.hudTint = 0xF04A3A;
// The linkage must match what the SWF exports:
r.iconName = "ERF_ICON__erf_core__fire";
api->RegisterReaction(r);
```


The HUD will pass this iconName down to AS2 in iconLinkages[], which then calls attachMovie(iconLinkage, ...) for the corresponding gauge slot.