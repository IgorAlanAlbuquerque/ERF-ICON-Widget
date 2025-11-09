#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Validador de registry:
- Garante que cada JSON tenha "namespace" e lista "icons"
- Garante padrão de linkage: ERF_ICON__<namespace>__<name>
- Detecta linkageIds duplicados entre arquivos
- Verifica se os arquivos existem (relativo à raiz do repo)
- (Opcional) checa dimensões máximas (requer Pillow)
Saída:
  - exit code 0: ok
  - exit code 1: erros encontrados
"""

import os, re, sys, json, glob

try:
    from PIL import Image  # opcional
    PIL_OK = True
except Exception:
    PIL_OK = False

ROOT     = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG_DIR  = os.path.join(ROOT, "registry")
ICONS    = os.path.join(ROOT, "icons")
MAX_W    = 128   # ajuste se quiser
MAX_H    = 128

NS_RX    = re.compile(r'^[a-z0-9_]+$')
LINK_RX  = re.compile(r'^ERF_ICON__([a-z0-9_]+)__([a-z0-9_]+)$')

def error(msg):
    print(f"[ERROR] {msg}", file=sys.stderr)

def warn(msg):
    print(f"[WARN]  {msg}", file=sys.stderr)

def info(msg):
    print(f"[INFO]  {msg}")

def main():
    if not os.path.isdir(REG_DIR):
        error(f"registry dir não encontrado: {REG_DIR}")
        return 1

    jsons = sorted(glob.glob(os.path.join(REG_DIR, "*.json")))
    if not jsons:
        info("Nenhum arquivo em registry/ (ok para repositório vazio).")
        return 0

    seen_linkages = set()
    ok = True

    for path in jsons:
        try:
            with open(path, "r", encoding="utf-8") as f:
                j = json.load(f)
        except Exception as e:
            error(f"Falha lendo {path}: {e}")
            ok = False
            continue

        ns = str(j.get("namespace", "")).strip()
        if not ns:
            error(f"{path}: campo 'namespace' ausente ou vazio.")
            ok = False
        elif not NS_RX.match(ns):
            error(f"{path}: namespace inválido '{ns}' (use [a-z0-9_]).")
            ok = False

        icons = j.get("icons", [])
        if not isinstance(icons, list):
            error(f"{path}: campo 'icons' deve ser lista.")
            ok = False
            continue

        for i, it in enumerate(icons):
            if not isinstance(it, dict):
                error(f"{path}: icons[{i}] deve ser objeto.")
                ok = False
                continue

            file_rel = it.get("file")
            linkage  = it.get("linkage")

            if not file_rel or not isinstance(file_rel, str):
                error(f"{path}: icons[{i}].file inválido.")
                ok = False
                continue
            if not linkage or not isinstance(linkage, str):
                error(f"{path}: icons[{i}].linkage inválido.")
                ok = False
                continue

            m = LINK_RX.match(linkage)
            if not m:
                error(f"{path}: linkage '{linkage}' inválido (esperado ERF_ICON__<ns>__<name>).")
                ok = False
            else:
                l_ns = m.group(1)
                if l_ns != ns:
                    error(f"{path}: linkage '{linkage}' não bate com namespace '{ns}'.")
                    ok = False

            # duplicatas globais
            if linkage in seen_linkages:
                error(f"{path}: linkage duplicado '{linkage}'.")
                ok = False
            else:
                seen_linkages.add(linkage)

            # arquivo existe?
            file_abs = file_rel
            if not os.path.isabs(file_abs):
                file_abs = os.path.normpath(os.path.join(ROOT, file_rel))
            if not os.path.exists(file_abs):
                error(f"{path}: arquivo não encontrado: {file_rel}")
                ok = False
            else:
                # checagem opcional de dimensões
                if PIL_OK and file_abs.lower().endswith((".png", ".jpg", ".jpeg")):
                    try:
                        with Image.open(file_abs) as im:
                            w, h = im.size
                            if w > MAX_W or h > MAX_H:
                                warn(f"{file_rel}: {w}x{h} > {MAX_W}x{MAX_H} (considere reduzir).")
                    except Exception as e:
                        warn(f"{file_rel}: não foi possível ler dimensões ({e}).")

    if ok:
        info("Registry OK.")
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())
