#!/usr/bin/env python3
import json
import subprocess
import glob
import os
import sys

FILTER = "lineage-17.1-20210904"
WORK_DIR = "/mnt/work"

os.makedirs(WORK_DIR, exist_ok=True)

files = glob.glob("system/**/*.json", recursive=True) + glob.glob("vendor/**/*.json", recursive=True)

for target in files:
    with open(target, "r") as fp:
        data = json.load(fp)

    for entry in data["response"]:
        if FILTER not in entry["filename"]:
            continue

        url = entry["url"]
        filename = entry["filename"]
        file_id = entry["id"]
        tag = f"dl-{file_id}"
        local_path = os.path.join(WORK_DIR, filename)

        # Skip if already pointing to our repo
        if "caot60002" in url:
            print(f"[skip] {filename} - already on our repo")
            continue

        print(f"[download] {filename}")
        subprocess.run(["wget", "-nv", "-O", local_path, url], check=True)

        print(f"[release] creating release {tag}")
        result = subprocess.run(
            ["gh", "release", "create", tag, local_path, "--target", "master"],
            capture_output=True, text=True
        )

        if result.returncode != 0:
            print(f"[error] {result.stderr}")
            os.remove(local_path)
            continue

        # Update URL to point to our repo
        entry["url"] = f"https://github.com/caot60002/waydroid_ota/releases/download/{tag}/{filename}"

        with open(target, "w") as fp:
            json.dump(data, fp, indent=4)

        os.remove(local_path)
        print(f"[done] {filename}")

print("\nAll done. Run: git add -A && git commit -m 'Update URLs' && git push")
