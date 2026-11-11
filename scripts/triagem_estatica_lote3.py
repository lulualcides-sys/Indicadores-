#!/usr/bin/env python3
"""Static indicators audit. Findings are hints, NOT repaint/non-repaint certification."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/"08_indicadores_originais/manifesto_lote3.json").read_text(encoding="utf8"))
patterns={
    "pine_request_security":r"request\.security\s*\(",
    "pine_security_lower_tf":r"request\.security_lower_tf\s*\(",
    "pine_lookahead_on":r"\bbarmerge\.lookahead_on\b",
    "pine_confirmed_check":r"\bbarstate\.isconfirmed\b",
    "pine_pivot":r"\bta\.pivot(?:high|low)\s*\(",
    "pine_negative_offset":r"\boffset\s*=\s*-\s*[A-Za-z0-9_]+",
    "mql5_oncalculate":r"\bOnCalculate\s*\(",
    "mql5_copybuffer":r"\bCopyBuffer\s*\(",
    "mql5_setindexbuffer":r"\bSetIndexBuffer\s*\(",
    "mql5_webrequest":r"\bWebRequest\s*\(",
    "mql5_import":r"(?m)^\s*#import\b",
}
out=[]
for file in manifest["files"]:
    if file["type"] not in ("mq5","pine"):continue
    data=(ROOT/file["path"]).read_text(encoding="utf8")
    row={"path":file["path"],"sha":file["git_blob_sha"],"kind":file["type"],
         "flags":{key:len(re.findall(pat,data)) for key,pat in patterns.items()}}
    if file["type"]=="mq5" and row["flags"]["mql5_webrequest"]+row["flags"]["mql5_import"]:
        row["security_note"]="External/network calls require manual review before compilation"
    if file["type"]=="pine" and (row["flags"]["pine_pivot"] or row["flags"]["pine_request_security"] or row["flags"]["pine_negative_offset"]):
        row["causality_note"]="Check pivot confirmation timestamp, HTF completed bars, and backdated markers"
    out.append(row)
assert len(out)==21, len(out)
print(json.dumps({"warning":"Static string checks only: do NOT infer performance, safety, or non-repaint from these flags.",
                  "total":len(out),"sources":out},ensure_ascii=False,indent=2))
