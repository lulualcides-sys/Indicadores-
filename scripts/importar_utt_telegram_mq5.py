#!/usr/bin/env python3
"""Download Telegram-linked source ZIPs without executing third-party files."""
import hashlib
import io
import json
import pathlib
import sys
import urllib.request
import zipfile

BASE=pathlib.Path(__file__).resolve().parents[1]
OUT=BASE/"08_indicadores_originais"/"12_utt_telegram_sources"
DATA=[
 ("buyers_sellers_profile","buyers-sellers-profile-dynamic-sr-deriv-mt5.zip","buyers-sellers-profile-dynamic-sr-mt5/","CC BY-NC-SA 4.0","Zeiierman"),
 ("liquidity_entry","liquidity-entry-signals.zip","liquidity-entry-signals/","CC BY-NC-SA 4.0","MarkitTick"),
 ("wick_sequence","wick-sequence-breakout-mt5.zip","wick-sequence-breakout-mt5/","MPL-2.0","Uncle_the_shooter"),
 ("adaptive_intelligence","adaptive-market-intelligence-mt5.zip","adaptive-market-intelligence-mt5/","MPL-2.0","InvestyourAsset"),
]
DOMAIN="https://ultimatetrading.tools"
EXTENSIONS={".mq5",".mqh",".mq4",".pine",".txt",".md",".license"}
def digest(b):
    return hashlib.sha256(b).hexdigest()
def get(filename):
    url=DOMAIN+"/wp-content/uploads/ut-src/"+filename
    req=urllib.request.Request(url,headers={"User-Agent":"Mozilla/5.0 (Nexus research archive)","Accept":"application/zip,*/*"})
    with urllib.request.urlopen(req,timeout=40) as r:
        body=r.read(12000001)
    if len(body)>12000000 or not zipfile.is_zipfile(io.BytesIO(body)):
        raise ValueError("Not a valid ZIP under 12MB")
    return body
def safe_name(name):
    p=pathlib.PurePosixPath(name.replace("\\","/"))
    if p.is_absolute() or ".." in p.parts or any(s.startswith(".") for s in p.parts):
        raise ValueError("Unsafe ZIP path")
    return p
def import_one(slug,zipname,product,license_name,author):
    raw=get(zipname)
    imported=[]
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        members=[f for f in archive.infolist() if not f.is_dir()]
        if len(members)>100 or sum(i.file_size for i in members)>12000000:
            raise ValueError("Too many files or uncompressed ZIP size")
        for entry in members:
            name=safe_name(entry.filename)
            if entry.file_size>2500000:
                continue
            if name.suffix.lower() not in EXTENSIONS and name.name.upper() not in {"README","LICENSE","COPYING"}:
                continue
            if entry.flag_bits&1:
                raise ValueError("Encrypted file")
            if ((entry.external_attr >> 16)&0o170000)==0o120000:
                raise ValueError("Symbolic link")
            content=archive.read(entry)
            dest=OUT/slug/pathlib.Path(*name.parts)
            dest.parent.mkdir(parents=True,exist_ok=True)
            dest.write_bytes(content)
            imported.append({"path":str(dest.relative_to(BASE)),"sha256":digest(content),"bytes":len(content)})
    if not any(x["path"].lower().endswith(".mq5") for x in imported):
        raise ValueError("No MQL5 source file found")
    return {"name":slug,"url":DOMAIN+"/product/"+product,"download_url":DOMAIN+"/wp-content/uploads/ut-src/"+zipname,"license_claim":license_name,"author_credit":author,"zip_sha256":digest(raw),"files":imported}
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    successes=[]
    problems=[]
    for args in DATA:
        try:
            group=import_one(*args)
            successes.append(group)
            print("IMPORTED",args[0],len(group["files"]))
        except Exception as e:
            problems.append({"source":args[0],"error":str(e)})
            print("FAILED",args[0],str(e),file=sys.stderr)
    payload={"channel":"https://t.me/s/ShepherdFxTradingTools","source":"https://ultimatetrading.tools/","method":"download ZIP linked from publisher, extract source/text only; never execute imported code","success":successes,"failures":problems}
    (OUT/"manifesto_downloads.json").write_text(json.dumps(payload,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    documentation=["# Arquivos-fonte MQ5 realmente recuperados via canal Telegram e site do publicador","","Canal: https://t.me/s/ShepherdFxTradingTools","Site: https://ultimatetrading.tools/","","Licenças informadas nas páginas dos produtos. Verificar os cabeçalhos de cada fonte antes de reutilizar. Fontes CC BY-NC-SA apenas para pesquisa não comercial.","","## Downloads concluídos"]
    for item in successes:
        documentation += ["","## "+item["name"],"Página: "+item["url"],"Autor: "+item["author_credit"],"Licença declarada: "+item["license_claim"],"SHA256 do ZIP: "+item["zip_sha256"],"Arquivos fonte/documentação: "+str(len(item["files"]))]
    if problems:
        documentation += ["","## Não recuperados"]
        for item in problems:
            documentation.append("- "+item["source"]+": "+item["error"])
    documentation += ["","Estes arquivos não foram compilados nem testados no MT5. Não há qualquer resultado financeiro comprovado. Inspecionar lógica, pivôs, MTF e repaint antes de usar."]
    (OUT/"README.md").write_text("\n".join(documentation)+"\n",encoding="utf-8")
    if not successes:
        raise SystemExit("No MQ5 source recovered, so do not claim source import")
if __name__=="__main__":
    main()
