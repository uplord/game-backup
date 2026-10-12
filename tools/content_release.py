#!/usr/bin/env python3
"""Validate and package a local content snapshot for a future CMS publishing pipeline.
Usage: python3 tools/content_release.py data/local/content.json --output data/releases
"""
import argparse, hashlib, json, pathlib, re, sys
TYPES = {"items", "enemies", "skills", "areas", "resources", "recipes", "npcs", "quests", "loot_tables", "shops", "objects"}
def validate(bundle):
    errors=[]
    if bundle.get("schema_version") != 1 or isinstance(bundle.get("schema_version"), bool): errors.append("schema_version must be 1")
    if not isinstance(bundle.get("content_version"),str) or not bundle["content_version"].strip():errors.append("content_version is required")
    definitions=bundle.get("definitions")
    if not isinstance(definitions,dict):return errors+["definitions must be an object"]
    ids={}
    for kind,entries in definitions.items():
        if kind not in TYPES:errors.append(f"Unknown type: {kind}");continue
        if not isinstance(entries,list):errors.append(f"{kind} must be an array");continue
        ids[kind]=set()
        for entry in entries:
            if not isinstance(entry,dict):errors.append(f"{kind} entry must be an object");continue
            key=entry.get("id")
            if not isinstance(key,str) or not re.fullmatch(r"[a-z0-9_]+",key):errors.append(f"Invalid {kind} ID: {key}");continue
            if key in ids[kind]:errors.append(f"Duplicate {kind} ID: {key}")
            ids[kind].add(key)
            if not isinstance(entry.get("name"),str) or not entry["name"].strip():errors.append(f"{kind}/{key} requires name")
    def ref(kind,key,where):
        if not isinstance(key,str) or key not in ids.get(kind,set()):errors.append(f"{where} references missing {kind}/{key}")
    for kind,entries in definitions.items():
        if not isinstance(entries,list):continue
        for e in entries:
            if not isinstance(e,dict):continue
            where=f"{kind}/{e.get('id','?')}"
            for field,target in ({"resources":{"item_id":"items","skill_id":"skills"},"enemies":{"loot_table_id":"loot_tables"},"recipes":{"skill_id":"skills"}}.get(kind,{})).items():
                if field in e:ref(target,e[field],where)
            for field,target in ({"recipes":{"ingredients":"items","outputs":"items"},"loot_tables":{"entries":"items"},"quests":{"rewards":"items"},"shops":{"stock":"items"}}.get(kind,{})).items():
                entries2=e.get(field,[])
                if not isinstance(entries2,list):errors.append(f"{where}/{field} must be an array");continue
                for item in entries2:
                    if not isinstance(item,dict) or "item_id" not in item:errors.append(f"{where}/{field} missing item_id")
                    else:ref(target,item["item_id"],where)
            for field in ({"resources":["required_level","respawn_seconds"],"enemies":["level","max_hp"]}.get(kind,[])):
                if field in e and (isinstance(e[field],bool) or not isinstance(e[field],(int,float)) or e[field]<0):errors.append(f"{where}/{field} must be non-negative")
    return errors

def main():
    ap=argparse.ArgumentParser();ap.add_argument("bundle",type=pathlib.Path);ap.add_argument("--output",type=pathlib.Path,default=pathlib.Path("data/releases"));args=ap.parse_args()
    try:bundle=json.loads(args.bundle.read_text())
    except (OSError,json.JSONDecodeError) as exc:print(exc,file=sys.stderr);return 1
    errors=validate(bundle)
    if errors:
        for error in errors:print("ERROR:",error,file=sys.stderr)
        return 1
    canonical=json.dumps(bundle,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode()
    digest=hashlib.sha256(canonical).hexdigest()
    version=bundle["content_version"]
    if not re.fullmatch(r"[a-zA-Z0-9_.-]+",version):print("Unsafe version name",file=sys.stderr);return 1
    args.output.mkdir(parents=True,exist_ok=True)
    target=args.output/(version+".json")
    if target.exists():
        print("Release already exists; published versions are immutable",file=sys.stderr);return 1
    target.write_text(json.dumps(bundle,indent=2,ensure_ascii=False)+"\n")
    (args.output/(version+".manifest.json")).write_text(json.dumps({"version":version,"schema_version":1,"sha256":digest,"definition_counts":{k:len(v) for k,v in bundle["definitions"].items()}},indent=2)+"\n")
    print(f"Published local snapshot: {target} SHA256 {digest}")
    return 0
if __name__=="__main__":sys.exit(main())
