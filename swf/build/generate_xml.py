#!/usr/bin/env python3
import json, os, sys, glob

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ROOT = os.environ.get("GITHUB_WORKSPACE", DEFAULT_ROOT)

ICONS    = os.path.join(ROOT, "icons")
REG      = os.path.join(ROOT, "registry")
TEMPLATE = os.path.join(ROOT, "swf", "template", "template.xml")  # opcional
OUT_XML  = os.path.join(ROOT, "dist", "ERF_UI.generated.xml")

def read_registry():
    entries = []
    for path in sorted(glob.glob(os.path.join(REG, "*.json"))):
        try:
            with open(path, "r", encoding="utf-8") as f:
                j = json.load(f)
            ns = j.get("namespace", "").strip()
            for it in j.get("icons", []):
                fpath   = it["file"]
                linkage = it["linkage"]
                entries.append({
                    "file": fpath,
                    "linkage": linkage
                })
        except Exception as e:
            print(f"[WARN] skipping {path}: {e}", file=sys.stderr)
    return entries

def emit_simple_movie(assets):
    # Gera um SWF (swfmill simple) com:
    # - biblioteca: ERF_Gauge export
    # - bitmaps + sprites exportados por linkage
    xml = []
    xml.append('<?xml version="1.0" encoding="UTF-8"?>')
    xml.append('<movie width="256" height="256" framerate="60" version="8">')
    xml.append('  <library>')
    xml.append('    <clip id="ERF_Gauge" export="ERF_Gauge"><frame/></clip>')
    # Bitmaps + sprites
    for idx, a in enumerate(assets):
        fid = f"bmp_{idx}"
        sid = f"spr_{idx}"
        # PNG direto
        xml.append(f'    <bitmap id="{fid}" import="{a["file"]}"/>')
        # Sprite que contém o bitmap
        xml.append(f'    <clip id="{sid}"><frame><place id="{fid}"/></frame></clip>')
        # Exporta o sprite com o linkage pedido
        xml.append(f'    <export asset="{sid}" name="{a["linkage"]}"/>')
    xml.append('  </library>')
    xml.append('  <frame/>')
    xml.append('</movie>')
    return "\n".join(xml)

def main():
    os.makedirs(os.path.join(ROOT, "dist"), exist_ok=True)

    assets = read_registry()
    # Normaliza caminhos relativos
    for a in assets:
        p = a["file"]
        if not os.path.isabs(p):
            a["file"] = os.path.normpath(os.path.join(ROOT, p))

    # Avisos de inexistentes (não falha build; só avisa)
    ok_assets = []
    for a in assets:
        if os.path.exists(a["file"]):
            ok_assets.append(a)
        else:
            print(f"[WARN] file not found: {a['file']}", file=sys.stderr)

    xml = emit_simple_movie(ok_assets)
    with open(OUT_XML, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"[OK] wrote {OUT_XML} with {len(ok_assets)} assets")

if __name__ == "__main__":
    main()
