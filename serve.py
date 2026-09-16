#!/usr/bin/env python3
"""Statischer Server ohne Cache.

Der eingebaute http.server schickt Last-Modified, der Browser haelt die
Seite dann minutenlang fest - das hat beim Entwickeln schon Zeit gekostet.
Hier geht jede Antwort mit no-store raus.
"""
import functools, http.server, os, socketserver, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8901
ROOT = os.path.dirname(os.path.abspath(__file__))


class NoCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def log_message(self, *a):
        pass


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('', PORT), functools.partial(NoCache, directory=ROOT)) as httpd:
    print(f'http://localhost:{PORT}/index.html')
    httpd.serve_forever()
