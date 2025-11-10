import json, os, sys, glob

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ROOT = os.environ.get("GITHUB_WORKSPACE", DEFAULT_ROOT)

REG_DIR  = os.path.join(ROOT, "registry")         
OUT_DIR  = os.path.join(ROOT, "dist")
OUT_XML  = os.path.join(OUT_DIR, "ERF_UI.generated.xml")

def read_registry():
    """Lê todos os JSONs em /registry/*.json e retorna lista de {file, linkage}."""
    entries = []
    paths = sorted(glob.glob(os.path.join(REG_DIR, "*.json")))
    if not paths:
        print(f"[WARN] no registry jsons found in {REG_DIR}", file=sys.stderr)
    for path in paths:
        try:
            with open(path, "r", encoding="utf-8") as f:
                j = json.load(f)
            
            for it in j.get("icons", []):
                fpath   = it["file"]
                linkage = it["linkage"]
                entries.append({"file": fpath, "linkage": linkage})
        except Exception as e:
            print(f"[WARN] skipping {path}: {e}", file=sys.stderr)
    return entries

def normalize_assets(assets):
    """Normaliza caminho dos arquivos e filtra os que existem."""
    ok = []
    for a in assets:
        p = a["file"]
        if not os.path.isabs(p):
            p = os.path.normpath(os.path.join(ROOT, p))
        if os.path.exists(p):
            ok.append({"file": p, "linkage": a["linkage"]})
        else:
            print(f"[WARN] file not found: {p}", file=sys.stderr)
    return ok

def emit_simple_movie(assets):
    """
    Gera XML em 'simple syntax' do swfmill.
    Exporta cada bitmap com 'export="<linkage>"' para permitir BitmapData.loadBitmap(linkage).
    """
    xml = []
    xml.append('<?xml version="1.0" encoding="UTF-8"?>')
    xml.append('<movie width="256" height="256" framerate="60" version="8">')
    xml.append('  <library>')
    
    xml.append('    <clip id="ERF_Gauge" export="ERF_Gauge"><frame/></clip>')

    for idx, a in enumerate(assets):
        fid = f"ico_{idx}"  
        
        xml.append(f'    <bitmap id="{fid}" src="{a["file"]}" export="{a["linkage"]}"/>')

    xml.append('  </library>')
    xml.append('  <frame/>')
    xml.append('</movie>')
    return "\n".join(xml)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    assets = read_registry()
    assets = normalize_assets(assets)

    xml = emit_simple_movie(assets)
    with open(OUT_XML, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"[OK] wrote {OUT_XML} with {len(assets)} assets")

if __name__ == "__main__":
    main()
