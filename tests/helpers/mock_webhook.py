"""Tiny webhook receiver for tests: records every POST as one JSON line.

usage: mock_webhook.py <requests.jsonl> <port-file>
Set MOCK_STATUS to make it answer with a different HTTP status.
"""
import http.server
import json
import os
import sys

OUT, PORT_FILE = sys.argv[1], sys.argv[2]


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        try:
            body = json.loads(raw)
        except ValueError:
            body = raw
        with open(OUT, "a", encoding="utf-8") as f:
            f.write(json.dumps({"path": self.path, "body": body}, ensure_ascii=False) + "\n")
        self.send_response(int(os.environ.get("MOCK_STATUS", "200")))
        self.end_headers()

    def log_message(self, *args):  # keep test output quiet
        pass


server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
with open(PORT_FILE, "w", encoding="utf-8") as f:
    f.write(str(server.server_port))
server.serve_forever()
