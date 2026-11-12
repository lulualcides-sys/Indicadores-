#!/usr/bin/env python3
"""Build one installable package from TEN unchanged original indicators + unified overlay."""
from __future__ import annotations
from pathlib import Path
import hashlib,json,zipfile,sys
ROOT=Path(__file__).resolve().parents[2]
HERE=ROOT/"tools/nexus_universal_visual"
MODELS=[["03_projetos_proprios/Nexus_Clean_Signals/v1.00/Nexus_Clean_Signals_NR.mq5","Nexus_Clean_Signals_NR.mq5"],["03_projetos_proprios/Nexus_Liquidity_Sweep/v1.00/Nexus_Liquidity_Sweep_NR.mq5","Nexus_Liquidity_Sweep_NR.mq5"],["03_projetos_proprios/Nexus_FVG_Retest/v1.00/Nexus_FVG_Retest_NR.mq5","Nexus_FVG_Retest_NR.mq5"],["03_projetos_proprios/Nexus_Structure_Break/v1.00/Nexus_Structure_Break_NR.mq5","Nexus_Structure_Break_NR.mq5"],["03_projetos_proprios/Nexus_Session_VWAP/v1.10/Nexus_Session_VWAP_NR_v1.10.mq5","Nexus_Session_VWAP_NR_v1.10.mq5"],["03_projetos_proprios/Nexus_Volatility_Squeeze/v1.00/Nexus_Volatility_Squeeze_NR.mq5","Nexus_Volatility_Squeeze_NR.mq5"],["03_projetos_proprios/Nexus_EMA_Trend_Pullback/v1.00/Nexus_EMA_Trend_Pullback_NR.mq5","Nexus_EMA_Trend_Pullback_NR.mq5"],["03_projetos_proprios/Nexus_Causal_Kernel/v1.00/Nexus_Causal_Kernel_NR.mq5","Nexus_Causal_Kernel_NR.mq5"],["03_projetos_proprios/Nexus_Three_Candle/v1.00/Nexus_Three_Candle_NR.mq5","Nexus_Three_Candle_NR.mq5"],["03_projetos_proprios/H1_Vector_Factor/v1.30/H1_Vector_Factor_M1.mq5","H1_Vector_Factor_M1.mq5"]]
OUTPUT=ROOT/"dist"/"Nexus_10_Indicadores_PadraoVisual_Instalacao.zip"

def build():
    wrapper=HERE/"Nexus_Visual_Unificado_TP_Painel_Som.mq5"
    guide=HERE/"LEIA_PRIMEIRO.md"
    entries=[(wrapper.name,wrapper),(guide.name,guide)]
    for path,name in MODELS:
        original=ROOT/path
        if not original.is_file():
            raise FileNotFoundError(str(original))
        code=original.read_text(encoding="utf-8")
        # All supported original indicators expose BUY=0 and SELL=1.
        for keyword in ("SetIndexBuffer(0,","SetIndexBuffer(1,"):
            if keyword not in code:
                raise ValueError(f"{original}: missing {keyword}")
        entries.append(("NexusBase/"+name,original))
    if len(entries)!=12 or len({x[0] for x in entries})!=12:
        raise ValueError("Expected 10 distinct models + wrapper + guide")
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    manifest={"package":"Nexus visual unificado 10 fontes v1.00",
              "compatibility":"source buffers 0=BUY,1=SELL",
              "disclaimer":"Simulated raw points only; MetaEditor compile and live validation required",
              "files":[]}
    with zipfile.ZipFile(OUTPUT,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for dest,source in entries:
            data=source.read_bytes()
            archive.writestr(dest,data)
            manifest["files"].append({"path":dest,"source":str(source.relative_to(ROOT)),
                                       "bytes":len(data),"sha256":hashlib.sha256(data).hexdigest()})
        archive.writestr("MANIFESTO_SHA256.json",json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    with zipfile.ZipFile(OUTPUT) as archive:
        allNames=archive.namelist()
        assert len(allNames)==13 and len(set(allNames))==13
        for entry in manifest["files"]:
            raw=archive.read(entry["path"])
            assert hashlib.sha256(raw).hexdigest()==entry["sha256"]
        assert sum(x.startswith("NexusBase/") for x in allNames)==10
    print(json.dumps({"file":str(OUTPUT),"zip_bytes":OUTPUT.stat().st_size,
                      "source_files":10,"entries":13}))
if __name__=="__main__":build()
