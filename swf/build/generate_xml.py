import json, os, sys, glob

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ROOT = os.environ.get("GITHUB_WORKSPACE", DEFAULT_ROOT)

REG_DIR  = os.path.join(ROOT, "registry")   
OUT_DIR  = os.path.join(ROOT, "dist")
OUT_XML  = os.path.join(OUT_DIR, "ERF_UI.generated.xml")

def rel_unix(path_abs: str) -> str:
    rel = os.path.relpath(path_abs, OUT_DIR)
    return rel.replace("\\", "/")

def read_assets():
    assets = []
    for path in sorted(glob.glob(os.path.join(REG_DIR, "*.json"))):
        try:
            with open(path, "r", encoding="utf-8") as f:
                j = json.load(f)
            for it in j.get("icons", []):
                f_rel   = it["file"]
                linkage = it["linkage"]
                f_abs = f_rel
                if not os.path.isabs(f_abs):
                    f_abs = os.path.normpath(os.path.join(ROOT, f_rel))
                if not os.path.exists(f_abs):
                    print(f"[WARN] file not found: {f_abs}", file=sys.stderr)
                    continue
                assets.append({"linkage": linkage, "file_abs": f_abs})
        except Exception as e:
            print(f"[WARN] skipping {path}: {e}", file=sys.stderr)
    return assets

def emit_xml(assets):
    out = []
    out.append('<?xml version="1.0" encoding="UTF-8"?>')
    out.append('<movie width="256" height="256" framerate="60" version="8">')
    out.append('  <frame>')
    out.append('    <library>')

    out.append('      <clip id="ERF_Gauge" export="ERF_Gauge"><frame/></clip>')

    for a in assets:
        out.append(
            f'      <clip id="{a["linkage"]}" import="{rel_unix(a["file_abs"])}"/>'
        )

    out.append('      <clip id="ERF_IconDepot" export="ERF_IconDepot">')
    out.append('        <frame>')
    for idx, a in enumerate(assets):
        out.append(
            f'          <place id="{a["linkage"]}" name="ic_{idx}" x="20000" y="20000" alpha="0"/>'
        )
    out.append('        </frame>')
    out.append('      </clip>')

    out.append('    </library>')
    out.append('  </frame>')
    out.append('</movie>')
    return "\n".join(out)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    assets = read_assets()
    xml = emit_xml(assets)
    with open(OUT_XML, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"[OK] wrote {OUT_XML} with {len(assets)} assets")

    if not assets:
        print("[WARN] 0 assets found. Check registry/*.json and icon paths.", file=sys.stderr)

if __name__ == "__main__":
    main()
