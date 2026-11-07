"""Reads `xcrun simctl list devices available -j` on stdin and prints the UDID of
an iPhone on the newest installed iOS runtime (preferring a 6.1" "Pro" model)."""
import json
import re
import sys

devices = json.load(sys.stdin)["devices"]


def version(runtime: str) -> list[int]:
    match = re.search(r"iOS-([\d-]+)$", runtime)
    return [int(part) for part in match.group(1).split("-")] if match else []


for runtime in sorted((r for r in devices if "SimRuntime.iOS" in r), key=version, reverse=True):
    phones = [d for d in devices[runtime] if d["name"].startswith("iPhone")]
    if not phones:
        continue
    preferred = [d for d in phones if "Pro" in d["name"] and "Max" not in d["name"]]
    print((preferred or phones)[-1]["udid"])
    sys.exit(0)

sys.exit("No available iPhone simulator found")
