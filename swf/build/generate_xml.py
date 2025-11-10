import json, os, sys, glob

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ROOT = os.environ.get("GITHUB_WORKSPACE", DEFAULT_ROOT)

REG_DIR  = os.path.join(ROOT, "registry") 
OUT_DIR  = os.path.join(ROOT, "dist")
OUT_XML  = os.path.join(OUT_DIR, "ERF_UI.generated.xml")

def _unix(p: str) -> str:
    return p.replace("\\", "/")

def read_registry():
    entries = []
    paths = sorted(glob.glob(os.path.join(REG_DIR, "*.json")))
    if not paths:
        print(f"[WARN] no registry jsons found in {REG_DIR}", file=sys.stderr)

    idx = 0
    for path in paths:
        try:
            with open(path, "r", encoding="utf-8") as f:
                j = json.load(f)
            icons = j.get("icons", [])
            for it in icons:
                frel    = it["file"]
                linkage = it["linkage"]
                fabs = frel
                if not os.path.isabs(fabs):
                    fabs = os.path.normpath(os.path.join(ROOT, frel))
                if not os.path.exists(fabs):
                    print(f"[WARN] file not found: {fabs}", file=sys.stderr)
                    continue
                fid = f"ico_{idx}"
                idx += 1
                entries.append({"id": fid, "file": _unix(fabs), "linkage": linkage})
        except Exception as e:
            print(f"[WARN] skipping {path}: {e}", file=sys.stderr)
    return entries

def emit_simple_movie(assets):
    xml = []
    xml.append('<?xml version="1.0" encoding="UTF-8"?>')
    xml.append('<movie width="256" height="256" framerate="60" version="8">')
    xml.append('  <library>')
    xml.append('    <clip id="ERF_Gauge" export="ERF_Gauge"><frame/></clip>')
    for a in assets:
        xml.append(f'    <bitmap id="{a["id"]}" src="{a["file"]}"/>')
    xml.append('  </library>')

    if assets:
        xml.append('  <export>')
        for a in assets:
            xml.append(f'    <symbol id="{a["id"]}" name="{a["linkage"]}"/>')
        xml.append('  </export>')

    xml.append('  <frame/>')
    xml.append('</movie>')
    return "\n".join(xml)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    assets = read_registry()

    xml = emit_simple_movie(assets)
    with open(OUT_XML, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"[OK] wrote {OUT_XML} with {len(assets)} assets -> {OUT_XML}")

    if not assets:
        print("[WARN] 0 assets found. Check your registry/*.json and icons/* paths.", file=sys.stderr)

if __name__ == "__main__":
    main()
