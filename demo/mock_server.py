#!/usr/bin/env python3
"""
Mock server for arrstatus demo/screenshots.
Runs fake API endpoints for all five services on their standard ports.

Ports:
  19080 — qBittorrent
  19081 — SABnzbd
  19878 — Radarr
  19989 — Sonarr
  19686 — Lidarr
"""

import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

# ── Mock data ─────────────────────────────────────────────────────────────────

QB_TRANSFER_INFO = {
    "dl_info_speed": 7_549_747,   # ~7.2 MB/s
    "up_info_speed":   786_432,   # ~768 KB/s
    "dl_info_data": 107_374_182_400,
    "up_info_data":  21_474_836_480,
    "connection_status": "connected",
}

QB_TORRENTS = [
    {
        "hash": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2",
        "name": "The.Vastness.S06E01.2160p.BluRay.x265-FLUX",
        "state": "downloading",
        "progress": 0.38,
        "dlspeed": 2_621_440,
        "upspeed": 0,
        "eta": 11400,
        "size": 8_589_934_592,
        "completed": 3_264_175_104,
    },
    {
        "hash": "b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3",
        "name": "Detachment.S02E05.2160p.WEB-DL.x265-FLUX",
        "state": "downloading",
        "progress": 0.67,
        "dlspeed": 1_887_437,
        "upspeed": 0,
        "eta": 3300,
        "size": 5_368_709_120,
        "completed": 3_597_034_611,
    },
    {
        "hash": "c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
        "name": "Iron.Citadel.2024.2160p.BluRay.REMUX-FLUX",
        "state": "downloading",
        "progress": 0.14,
        "dlspeed": 3_040_870,
        "upspeed": 0,
        "eta": 28800,
        "size": 55_834_574_848,
        "completed": 7_816_840_478,
    },
]

QB_SEEDING = [
    {
        "hash": "d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5",
        "name": "archlinux-2025.03.01-x86_64.iso",
        "state": "uploading",
        "progress": 1.0,
        "dlspeed": 0,
        "upspeed": 524_288,
        "eta": -1,
        "size": 1_153_433_600,
        "completed": 1_153_433_600,
    },
    {
        "hash": "e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6",
        "name": "debian-12.9.0-amd64-netinst.iso",
        "state": "uploading",
        "progress": 1.0,
        "dlspeed": 0,
        "upspeed": 262_144,
        "eta": -1,
        "size": 661_651_456,
        "completed": 661_651_456,
    },
]

SAB_QUEUE = {
    "queue": {
        "speed": "9420.0 K",
        "kbpersec": "9420.0",
        "mbleft": "8540.2",
        "mb": "24576.0",
        "noofslots": 2,
        "slots": [
            {
                "nzo_id": "SABnzbd_nzo_demo001",
                "filename": "Neon Requiem (2025) REMUX 2160p HDR",
                "status": "Downloading",
                "percentage": "71",
                "mb": "14336.0",
                "mbleft": "4157.4",
                "timeleft": "0:29:00",
                "cat": "movies",
                "priority": "Normal",
            },
            {
                "nzo_id": "SABnzbd_nzo_demo002",
                "filename": "Galactic Wanderer (2024) BluRay 2160p DV",
                "status": "Downloading",
                "percentage": "23",
                "mb": "10240.0",
                "mbleft": "7882.8",
                "timeleft": "3:42:00",
                "cat": "movies",
                "priority": "Normal",
            },
        ],
    }
}

RADARR_QUEUE = {
    "page": 1,
    "pageSize": 20,
    "totalRecords": 3,
    "records": [
        {
            "id": 101,
            "movieId": 11,
            "title": "Iron.Citadel.2024.2160p.BluRay.REMUX-FLUX",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 55_834_574_848,
            "sizeleft": 48_018_454_938,
            "timeleft": "08:00:00",
            "movie": {"id": 11, "title": "Iron Citadel", "year": 2024},
        },
        {
            "id": 102,
            "movieId": 12,
            "title": "Neon.Requiem.2025.2160p.REMUX-FLUX",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 48_318_382_080,
            "sizeleft": 14_012_330_803,
            "timeleft": "00:29:00",
            "movie": {"id": 12, "title": "Neon Requiem", "year": 2025},
        },
        {
            "id": 103,
            "movieId": 13,
            "title": "The.Last.Horizon.2023.2160p.BluRay.x265-FLUX",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "importPending",
            "size": 12_884_901_888,
            "sizeleft": 0,
            "timeleft": "",
            "movie": {"id": 13, "title": "The Last Horizon", "year": 2023},
        },
    ],
}

SONARR_QUEUE = {
    "page": 1,
    "pageSize": 20,
    "totalRecords": 4,
    "records": [
        {
            "id": 201,
            "seriesId": 1,
            "episodeId": 101,
            "title": "The.Vastness.S06E01.2160p.BluRay.x265-FLUX",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 8_589_934_592,
            "sizeleft": 5_325_754_446,
            "timeleft": "03:10:00",
            "series": {"id": 1, "title": "The Vastness", "year": 2015},
            "episode": {
                "id": 101, "seriesId": 1,
                "seasonNumber": 6, "episodeNumber": 1,
                "title": "Into the Deep",
            },
        },
        {
            "id": 202,
            "seriesId": 2,
            "episodeId": 207,
            "title": "Detachment.S02E05.2160p.WEB-DL.x265-FLUX",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 5_368_709_120,
            "sizeleft": 1_771_674_009,
            "timeleft": "00:55:00",
            "series": {"id": 2, "title": "Detachment", "year": 2022},
            "episode": {
                "id": 207, "seriesId": 2,
                "seasonNumber": 2, "episodeNumber": 5,
                "title": "The Wooden Horse",
            },
        },
        {
            "id": 203,
            "seriesId": 3,
            "episodeId": 305,
            "title": "North.Park.S05E01.2160p.BluRay.x265-FLUX",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 3_221_225_472,
            "sizeleft": 1_996_158_791,
            "timeleft": "01:20:00",
            "series": {"id": 3, "title": "North Park", "year": 1997},
            "episode": {
                "id": 305, "seriesId": 3,
                "seasonNumber": 5, "episodeNumber": 1,
                "title": "It Melts the Snow",
            },
        },
        {
            "id": 204,
            "seriesId": 4,
            "episodeId": 410,
            "title": "Breaking.Good.S04E10.2160p.WEB-DL.x265-FLUX",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "importPending",
            "size": 4_294_967_296,
            "sizeleft": 0,
            "timeleft": "",
            "series": {"id": 4, "title": "Breaking Good", "year": 2008},
            "episode": {
                "id": 410, "seriesId": 4,
                "seasonNumber": 4, "episodeNumber": 10,
                "title": "Azul",
            },
        },
    ],
}

LIDARR_QUEUE = {
    "page": 1,
    "pageSize": 20,
    "totalRecords": 3,
    "records": [
        {
            "id": 301,
            "artistId": 1,
            "albumId": 11,
            "title": "Colossal.Attack-Trapezoid-FLAC-1998",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 429_496_729,
            "sizeleft": 214_748_364,
            "timeleft": "00:12:00",
            "artist": {"id": 1, "artistName": "Colossal Attack"},
            "album": {"id": 11, "title": "Trapezoid", "releaseDate": "1998-04-20"},
        },
        {
            "id": 302,
            "artistId": 2,
            "albumId": 21,
            "title": "Crimson.Zeppelin-Houses.of.the.Sacred-FLAC-1973",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "downloading",
            "size": 644_245_094,
            "sizeleft": 38_654_705,
            "timeleft": "00:03:00",
            "artist": {"id": 2, "artistName": "Crimson Zeppelin"},
            "album": {"id": 21, "title": "Houses of the Sacred", "releaseDate": "1973-05-28"},
        },
        {
            "id": 303,
            "artistId": 3,
            "albumId": 31,
            "title": "The.Mend-Cured-FLAC-1989",
            "status": "downloading",
            "trackedDownloadStatus": "ok",
            "trackedDownloadState": "importPending",
            "size": 386_547_056,
            "sizeleft": 0,
            "timeleft": "",
            "artist": {"id": 3, "artistName": "The Mend"},
            "album": {"id": 31, "title": "Cured", "releaseDate": "1989-05-01"},
        },
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
