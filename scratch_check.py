import json

with open(r'C:\Users\geert\.gemini\antigravity-ide\brain\675b21b6-b2c7-41c6-a630-370dd790e4d8\.system_generated\logs\transcript.jsonl', 'r', encoding='utf-8') as f:
    for line in f:
        d = json.loads(line)
        idx = d.get('step_index', 0)
        if idx in (352, 353):
            print(f"Step {idx}: {d.get('type')}")
            print(d.get('content') or d.get('tool_calls'))
