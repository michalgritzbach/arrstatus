#!/usr/bin/env python3
"""
Mock server for arrstatus demo/screenshots.
Runs fake API endpoints for all five services on their standard ports.

Ports:
  8080 — qBittorrent
  8081 — SABnzbd
  7878 — Radarr
  8989 — Sonarr
  8686 — Lidarr
"""

import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

# ── Mock data ─────────────────────────────────────────────────────────────────

QB_TRANSFER_INFO = {
    "dl_info_speed": 3_355_443,   # ~3.2 MB/s
    "up_info_speed":   524_288,   # ~512 KB/s
    "dl_info_data": 107_374_182_400,
    "up_info_data":  21_474_836_480,
    "connection_status": "connected",
}

QB_TORRENTS = [
    {
        "hash": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2",
        "name": "The.Expanse.S06E01.2160p.BluRay.x265-GROUP",
        "state": "downloading",
        "progress": 0.42,
        "dlspeed": 1_887_437,
        "upspeed": 0,
        "eta": 9000,
        "size": 8_589_934_592,
        "completed": 3_607_728_742,
    },
    {
        "hash": "b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3",
        "name": "Severance.S02E05.2160p.WEB-DL.x265-GROUP",
        "state": "downloading",
        "progress": 0.71,
        "dlspeed": 1_468_006,
        "upspeed": 0,
        "eta": 2700,
        "size": 5_368_709_120,
        "completed": 3_811_783_475,
    },
]

QB_SEEDING = [
    {
        "hash": "c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
        "name": "ubuntu-24.04.1-desktop-amd64.iso",
        "state": "uploading",
        "progress": 1.0,
        "dlspeed": 0,
        "upspeed": 524_288,
        "eta": -1,
        "size": 6_114_762_752,
        "completed": 6_114_762_752,
    },
]

SAB_QUEUE = {
    "queue": {
        "speed": "8704.0 K",
        "kbpersec": "8704.0",
        "mbleft": "4721.3",
        "mb": "13107.2",
        "noofslots": 1,
        "slots": [
            {
                "nzo_id": "SABnzbd_nzo_demo001",
                "filename": "Blade Runner 2049 (2017) REMUX 2160p",
                "status": "Downloading",
                "percentage": "64",
                "mb": "13107.2",
                "mbleft": "4721.3",
                "timeleft": "1:12:00",
                "eta": "Tue 13:45",
                "cat": "movies",
                "priority": "Normal",
            }
        ],
    }
}

RADARR_QUEUE = {
    "page": 1,
    "pageSize": 20,
    "totalRecords": 1,
    "records": [
        {
            "id": 101,
            "movieId": 42,
            "title": "Dune.Part.Two.2024.2160p.BluRay.x265-GROUP",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 55_834_574_848,
            "sizeleft": 23_448_961_638,
            "timeleft": "01:20:00",
            "movie": {
                "id": 42,
                "title": "Dune: Part Two",
                "year": 2024,
                "tmdbId": 693134,
                "imdbId": "tt15239678",
            },
        }
    ],
}

SONARR_QUEUE = {
    "page": 1,
    "pageSize": 20,
    "totalRecords": 1,
    "records": [
        {
            "id": 201,
            "seriesId": 7,
            "episodeId": 307,
            "title": "Severance.S02E05.2160p.WEB-DL.x265-GROUP",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 5_368_709_120,
            "sizeleft": 1_557_924_045,
            "timeleft": "00:45:00",
            "series": {
                "id": 7,
                "title": "Severance",
                "year": 2022,
                "tvdbId": 381584,
            },
            "episode": {
                "id": 307,
                "seriesId": 7,
                "seasonNumber": 2,
                "episodeNumber": 5,
                "title": "Trojan's Horse",
                "airDate": "2025-02-28",
            },
        }
    ],
}

LIDARR_QUEUE = {
    "page": 1,
    "pageSize": 20,
    "totalRecords": 1,
    "records": [
        {
            "id": 301,
            "artistId": 9,
            "albumId": 15,
            "title": "Massive.Attack-Mezzanine-FLAC-1998",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 429_496_729,
            "sizeleft": 278_922_374,
            "timeleft": "00:18:00",
            "artist": {
                "id": 9,
                "artistName": "Massive Attack",
                "foreignArtistId": "6d7a7b1e-5b1c-4b1c-8b1c-4b1c8b1c4b1c",
            },
            "album": {
                "id": 15,
                "title": "Mezzanine",
                "releaseDate": "1998-04-20",
                "foreignAlbumId": "abc123",
            },
        }
    ],
}

# ── Request handlers ──────────────────────────────────────────────────────────


def make_handler(service_name, routes):
    """Return a handler class pre-loaded with the given route table."""

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            print(f"[{service_name}] {fmt % args}")

        def send_json(self, data, status=200):
            body = json.dumps(data).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", len(body))
            self.end_headers()
            self.wfile.write(body)

        def send_text(self, text, status=200):
            body = text.encode()
            self.send_response(status)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", len(body))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            path = urlparse(self.path).path
            handler = routes.get(("POST", path))
            if handler:
                handler(self)
            else:
                self.send_text("Not Found", 404)

        def do_GET(self):
            path = urlparse(self.path).path
            # Try exact match first, then prefix match
            handler = routes.get(("GET", path))
            if not handler:
                for (method, route), h in routes.items():
                    if method == "GET" and path.startswith(route):
                        handler = h
                        break
            if handler:
                handler(self)
            else:
                self.send_text("Not Found", 404)

    return Handler


def qb_login(handler):
    handler.rfile.read(int(handler.headers.get("Content-Length", 0)))
    handler.send_text("Ok.")


def qb_transfer_info(handler):
    handler.send_json(QB_TRANSFER_INFO)


def qb_torrents_info(handler):
    handler.send_json(QB_TORRENTS + QB_SEEDING)


QB_ROUTES = {
    ("POST", "/api/v2/auth/login"): qb_login,
    ("GET",  "/api/v2/transfer/info"): qb_transfer_info,
    ("GET",  "/api/v2/torrents/info"): qb_torrents_info,
}


def sab_api(handler):
    handler.send_json(SAB_QUEUE)


SAB_ROUTES = {
    ("GET", "/api"): sab_api,
}


def radarr_queue(handler):
    handler.send_json(RADARR_QUEUE)


RADARR_ROUTES = {
    ("GET", "/api/v3/queue"): radarr_queue,
}


def sonarr_queue(handler):
    handler.send_json(SONARR_QUEUE)


SONARR_ROUTES = {
    ("GET", "/api/v3/queue"): sonarr_queue,
}


def lidarr_queue(handler):
    handler.send_json(LIDARR_QUEUE)


LIDARR_ROUTES = {
    ("GET", "/api/v1/queue"): lidarr_queue,
}

# ── Server startup ─────────────────────────────────────────────────────────────

SERVICES = [
    ("qBittorrent", 19080, QB_ROUTES),
    ("SABnzbd",     19081, SAB_ROUTES),
    ("Radarr",      19878, RADARR_ROUTES),
    ("Sonarr",      19989, SONARR_ROUTES),
    ("Lidarr",      19686, LIDARR_ROUTES),
]


class ReusableHTTPServer(HTTPServer):
    allow_reuse_address = True


def start_server(name, port, routes):
    handler = make_handler(name, routes)
    server = ReusableHTTPServer(("127.0.0.1", port), handler)
    print(f"  {name:12} → http://127.0.0.1:{port}")
    server.serve_forever()


if __name__ == "__main__":
    print("Starting mock servers:")
    threads = []
    for name, port, routes in SERVICES:
        t = threading.Thread(target=start_server, args=(name, port, routes), daemon=True)
        t.start()
        threads.append(t)

    print("\nAll services running. Press Ctrl+C to stop.\n")
    try:
        for t in threads:
            t.join()
    except KeyboardInterrupt:
        print("\nStopped.")
