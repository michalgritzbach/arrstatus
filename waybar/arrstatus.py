#!/usr/bin/env python3
"""
arrstatus waybar widget
Reads ~/.config/arrstatus/arrstatus.conf and outputs waybar JSON.

Waybar JSON format (return-type: json):
  text       – string shown in the bar
  tooltip    – hover text; supports Pango markup (<b>, <i>, <span color="…">, newlines)
  class      – CSS class applied to the module ("downloading", "idle", "error")
  alt        – alternative text for format-alt
  percentage – integer 0-100 (usable in format as {percentage})

Waybar module config example:
    "custom/arrstatus": {
        "exec": "~/.config/waybar/scripts/arrstatus.py",
        "interval": 10,
        "return-type": "json",
        "format": "{}",
        "tooltip": true
    }
"""

import argparse
import configparser
import http.cookiejar
import json
import time
import urllib.error
import urllib.parse
import urllib.request

CONFIG_PATH = "~/.config/arrstatus/arrstatus.conf"


DEFAULT_CONFIG = """\
# arrstatus configuration
# Edit this file to configure your services.
# Changes are picked up automatically (no restart required).

[general]
poll_interval = 10

[qbittorrent]
enabled = false
url = http://localhost:8080
webui_url =
username = admin
password =

[sabnzbd]
enabled = false
url = http://localhost:8080
webui_url =
api_key =

[radarr]
enabled = false
url = http://localhost:7878
webui_url =
api_key =

[sonarr]
enabled = false
url = http://localhost:8989
webui_url =
api_key =

[lidarr]
enabled = false
url = http://localhost:8686
webui_url =
api_key =
"""


def load_config():
    import os

    path = os.path.expanduser(CONFIG_PATH)
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(DEFAULT_CONFIG)
    cfg = configparser.ConfigParser(default_section="__none__")
    cfg.read(path)
    return cfg


def get(cfg, section, key, fallback=""):
    try:
        return cfg.get(section, key)
    except (configparser.NoSectionError, configparser.NoOptionError):
        return fallback


def enabled(cfg, section):
    v = get(cfg, section, "enabled", "false").lower()
    return v in ("true", "1", "yes")


def format_speed(bps):
    bps = float(bps)
    if bps >= 1_073_741_824:
        return f"{bps / 1_073_741_824:.1f} GB/s"
    if bps >= 1_048_576:
        return f"{bps / 1_048_576:.1f} MB/s"
    if bps >= 1024:
        return f"{bps / 1024:.0f} KB/s"
    return f"{bps:.0f} B/s"


def format_eta_seconds(seconds):
    if seconds <= 0 or seconds >= 8640000:
        return ""
    d, rem = divmod(int(seconds), 86400)
    h, rem = divmod(rem, 3600)
    m = rem // 60
    if d:
        return f"{d}d {h}h"
    if h:
        return f"{h}h {m}m"
    if m:
        return f"{m}m"
    return "<1m"


def format_eta_timestr(timestr):
    """Parse arr timeleft strings: 'HH:MM:SS' or 'D.HH:MM:SS'"""
    if not timestr:
        return ""
    try:
        if "." in timestr:
            days_part, hms = timestr.split(".", 1)
            days = int(days_part)
        else:
            days, hms = 0, timestr
        parts = hms.split(":")
        h, m = int(parts[0]), int(parts[1])
        if days:
            return f"{days}d {h}h"
        if h:
            return f"{h}h {m}m"
        if m:
            return f"{m}m"
        return "<1m"
    except (ValueError, IndexError):
        return timestr


def pango_escape(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def http_get(url, headers=None, timeout=10):
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


# ── qBittorrent ──────────────────────────────────────────────────────────────
#
# POST /api/v2/auth/login  body: username=…&password=…
#   → "Ok." on success, "Fails." on bad credentials
#
# GET /api/v2/transfer/info
#   {
#     "dl_info_speed":  int,   # bytes/s global download speed
#     "up_info_speed":  int,   # bytes/s global upload speed
#     "dl_info_data":   int,   # total bytes downloaded this session
#     "up_info_data":   int,   # total bytes uploaded this session
#     "connection_status": str # "connected" | "firewalled" | "disconnected"
#   }
#
# GET /api/v2/torrents/info?filter=downloading
#   [ {
#     "hash":      str,
#     "name":      str,
#     "state":     str,   # "downloading" | "uploading" | "stalledDL" | "pausedDL" | …
#     "progress":  float, # 0.0–1.0
#     "dlspeed":   int,   # bytes/s
#     "upspeed":   int,   # bytes/s
#     "eta":       int,   # seconds remaining (-1 = unknown)
#     "size":      int,   # total bytes
#     "completed": int,   # bytes completed
#     "category":  str,
#     "tags":      str,
#     "added_on":  int,   # unix timestamp
#     "ratio":     float
#   }, … ]


def fetch_qbittorrent(cfg):
    base = get(cfg, "qbittorrent", "url").rstrip("/")
    user = get(cfg, "qbittorrent", "username")
    pwd = get(cfg, "qbittorrent", "password")

    jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))

    login_data = f"username={urllib.parse.quote(user)}&password={urllib.parse.quote(pwd)}".encode()
    login_req = urllib.request.Request(f"{base}/api/v2/auth/login", data=login_data)
    with opener.open(login_req, timeout=10) as resp:
        body = resp.read().decode()
        if body.strip() != "Ok.":
            return None, "login failed"

    with opener.open(f"{base}/api/v2/transfer/info", timeout=10) as resp:
        info = json.loads(resp.read())

    with opener.open(
        f"{base}/api/v2/torrents/info?filter=downloading", timeout=10
    ) as resp:
        torrents = json.loads(resp.read())

    dl_speed = info.get("dl_info_speed", 0)
    up_speed = info.get("up_info_speed", 0)
    active = [t for t in torrents if t.get("dlspeed", 0) > 0]
    uploading = [
        t for t in torrents if t.get("upspeed", 0) > 0 and t.get("dlspeed", 0) == 0
    ]
    return {
        "dl_speed": dl_speed,
        "up_speed": up_speed,
        "active": active,
        "uploading": uploading,
    }, None


def qb_torrent_status(t):
    parts = []
    pct = int(t.get("progress", 0) * 100)
    parts.append(f"{pct}%")
    dl = t.get("dlspeed", 0)
    if dl > 0:
        parts.append(f"↓ {format_speed(dl)}")
    eta = t.get("eta", -1)
    s = format_eta_seconds(eta)
    if s:
        parts.append(s)
    return "  ".join(parts)


# ── SABnzbd ──────────────────────────────────────────────────────────────────
#
# GET /api?mode=queue&output=json&apikey=…
#   {
#     "queue": {
#       "speed":      str,   # human-readable, e.g. "55.8 M" — unit suffix varies (K/M/G)
#       "kbpersec":   str,   # numeric KB/s, e.g. "57141.63" — preferred for math
#       "speedlimit": str,   # configured speed limit
#       "mbleft":     str,   # MB remaining in queue
#       "mb":         str,   # total MB in queue
#       "noofslots":  int,   # total slots (including paused)
#       "slots": [ {
#         "nzo_id":     str,
#         "filename":   str,
#         "status":     str,    # "Downloading" | "Paused" | "Queued" | "Verifying" | "Repairing" | "Extracting"
#         "percentage": str,    # "45" (no % sign)
#         "mb":         str,    # total MB
#         "mbleft":     str,    # MB remaining
#         "timeleft":   str,    # "H:MM:SS"
#         "eta":        str,    # human-readable ETA or "unknown"
#         "cat":        str,    # category
#         "avg_age":    str,    # average article age
#         "priority":   str
#       }, … ]
#     }
#   }
#
# Note: url in config should be the SABnzbd base, e.g. http://localhost:8080
# If SABnzbd runs under a path prefix (rare), append it: http://host:8080/sabnzbd


def fetch_sabnzbd(cfg):
    base = get(cfg, "sabnzbd", "url").rstrip("/")
    api_key = get(cfg, "sabnzbd", "api_key")
    url = f"{base}/api?mode=queue&output=json&apikey={api_key}"
    data = http_get(url)
    queue = data.get("queue", {})
    try:
        speed_kbps = float(queue.get("kbpersec", "0"))
    except ValueError:
        speed_kbps = 0
    slots = queue.get("slots", [])
    active = [s for s in slots if s.get("status", "").lower() == "downloading"]
    return {"dl_speed": speed_kbps * 1024, "active": active}, None


def sab_slot_status(slot):
    parts = []
    pct = slot.get("percentage", "")
    if pct:
        parts.append(f"{pct}%")
    tl = slot.get("timeleft", "")
    if tl and tl != "0:00:00":
        # SABnzbd gives H:MM:SS
        parts.append(tl)
    return "  ".join(parts)


# ── Radarr ───────────────────────────────────────────────────────────────────
#
# GET /api/v3/queue?includeMovie=true   header: X-Api-Key: …
#   {
#     "page": int, "pageSize": int, "totalRecords": int,
#     "records": [ {
#       "id":                    int,
#       "movieId":               int,
#       "title":                 str,   # release title (not movie title)
#       "status":                str,   # "queued" | "downloading" | "completed" | "failed" | "warning"
#       "trackedDownloadStatus": str,   # "ok" | "warning" | "error"
#       "trackedDownloadState":  str,   # "downloading" | "importPending" | "importing" | "imported" | "failedPending" | "failed"
#       "size":                  float, # bytes
#       "sizeleft":              float, # bytes remaining
#       "timeleft":              str,   # "D.HH:MM:SS" or "HH:MM:SS"
#       "estimatedCompletionTime": str, # ISO 8601 datetime
#       "indexer":               str,
#       "downloadClient":        str,
#       "movie": {
#         "id":        int,
#         "title":     str,
#         "year":      int,
#         "tmdbId":    int,
#         "imdbId":    str,
#         "genres":    [str],
#         "runtime":   int,   # minutes
#         "studio":    str,
#         "overview":  str,
#         "ratings":   {"imdb": {"value": float}, "tmdb": {"value": float}}
#       }
#     }, … ]
#   }
#
# ── Sonarr ────────────────────────────────────────────────────────────────────
#
# GET /api/v3/queue?includeSeries=true&includeEpisode=true   header: X-Api-Key: …
#   {
#     "page": int, "pageSize": int, "totalRecords": int,
#     "records": [ {
#       "id":                    int,
#       "seriesId":              int,
#       "episodeId":             int,
#       "title":                 str,   # release title
#       "status":                str,
#       "trackedDownloadStatus": str,   # "ok" | "warning" | "error"
#       "trackedDownloadState":  str,   # "downloading" | "importPending" | …
#       "size":                  float,
#       "sizeleft":              float,
#       "timeleft":              str,
#       "estimatedCompletionTime": str,
#       "indexer":               str,
#       "downloadClient":        str,
#       "series": {
#         "id":          int,
#         "title":       str,
#         "year":        int,
#         "tvdbId":      int,
#         "imdbId":      str,
#         "genres":      [str],
#         "network":     str,
#         "overview":    str,
#         "runtime":     int,    # minutes per episode
#         "seriesType":  str     # "standard" | "daily" | "anime"
#       },
#       "episode": {
#         "id":            int,
#         "seriesId":      int,
#         "seasonNumber":  int,
#         "episodeNumber": int,
#         "title":         str,  # episode title
#         "airDate":       str,  # "YYYY-MM-DD"
#         "overview":      str,
#         "runtime":       int
#       }
#     }, … ]
#   }
#
# ── Lidarr ────────────────────────────────────────────────────────────────────
#
# GET /api/v1/queue?includeArtist=true&includeAlbum=true   header: X-Api-Key: …
#   {
#     "page": int, "pageSize": int, "totalRecords": int,
#     "records": [ {
#       "id":                    int,
#       "artistId":              int,
#       "albumId":               int,
#       "title":                 str,   # release title
#       "status":                str,
#       "trackedDownloadStatus": str,   # "ok" | "warning" | "error"
#       "trackedDownloadState":  str,   # "downloading" | "importPending" | …
#       "size":                  float,
#       "sizeleft":              float,
#       "timeleft":              str,
#       "estimatedCompletionTime": str,
#       "indexer":               str,
#       "downloadClient":        str,
#       "artist": {
#         "id":               int,
#         "artistName":       str,
#         "foreignArtistId":  str,   # MusicBrainz artist ID
#         "genres":           [str],
#         "overview":         str,
#         "ratings":          {"value": float, "votes": int}
#       },
#       "album": {
#         "id":              int,
#         "title":           str,
#         "foreignAlbumId":  str,   # MusicBrainz release group ID
#         "releaseDate":     str,   # "YYYY-MM-DD"
#         "genres":          [str],
#         "label":           [str],
#         "duration":        int,   # milliseconds
#         "ratings":         {"value": float, "votes": int},
#         "artistId":        int
#       }
#     }, … ]
#   }


def fetch_arr_queue(base, api_key, include_param):
    url = f"{base.rstrip('/')}/api/v3/queue?{include_param}"
    headers = {"X-Api-Key": api_key}
    data = http_get(url, headers=headers)
    records = data.get("records", data) if isinstance(data, dict) else data
    active = [r for r in records if _arr_is_active(r)]
    return active, None


def fetch_lidarr_queue(base, api_key):
    url = f"{base.rstrip('/')}/api/v1/queue?includeArtist=true&includeAlbum=true"
    headers = {"X-Api-Key": api_key}
    data = http_get(url, headers=headers)
    records = data.get("records", data) if isinstance(data, dict) else data
    active = [r for r in records if _arr_is_active(r)]
    return active, None


def _arr_is_active(item):
    state = (item.get("trackedDownloadState") or "").lower()
    status = (item.get("trackedDownloadStatus") or "").lower()
    return state in ("downloading", "importpending") or status == "warning"


def _nested_get(d, dotted_key):
    val = d
    for part in dotted_key.split("."):
        if not isinstance(val, dict):
            return None
        val = val.get(part)
    return val if isinstance(val, str) and val else None


def arr_display_title(item, title_keys):
    for key in title_keys:
        v = _nested_get(item, key)
        if v:
            return v
    return item.get("title", "Unknown")


def arr_display_status(item):
    state = (item.get("trackedDownloadState") or "").lower()
    dl_status = (item.get("trackedDownloadStatus") or "").lower()

    if state == "downloading":
        label = "Downloading"
    elif state == "importpending":
        return "Importing"
    elif dl_status == "warning":
        return "Stalled"
    else:
        return (item.get("status") or "").capitalize()

    parts = []
    size = item.get("size")
    sizeleft = item.get("sizeleft")
    if size and sizeleft and float(size) > 0:
        pct = int((float(size) - float(sizeleft)) / float(size) * 100)
        parts.append(f"{pct}%")
    eta = format_eta_timestr(item.get("timeleft", ""))
    if eta:
        parts.append(eta)

    if parts:
        return label + " · " + " · ".join(parts)
    return label


# ── Tooltip builder ───────────────────────────────────────────────────────────


def section_header(name):
    return f"<b>{pango_escape(name)}</b>"


def item_line(title, status):
    return f"  {pango_escape(title)}   <span alpha='70%'>{pango_escape(status)}</span>"


def build_tooltip_qbittorrent(result):
    dl = result["dl_speed"]
    up = result["up_speed"]
    dl_count = len(result["active"])
    up_count = len(result["uploading"])
    return [
        section_header("qBittorrent"),
        item_line(
            f"↓ {format_speed(dl)}",
            f"{dl_count} {'torrent' if dl_count == 1 else 'torrents'}",
        ),
        item_line(
            f"↑ {format_speed(up)}",
            f"{up_count} {'torrent' if up_count == 1 else 'torrents'}",
        ),
    ]


def build_tooltip_sabnzbd(result):
    lines = []
    dl = result["dl_speed"]
    active = result["active"]
    count = len(active)
    lines.append(
        section_header("SABnzbd")
        + f"   <span alpha='70%'>↓ {format_speed(dl)}  {count} {'download' if count == 1 else 'downloads'}</span>"
    )
    for s in active:
        lines.append(item_line(s.get("filename", "Unknown"), sab_slot_status(s)))
    return lines


def build_tooltip_arr(name, items, title_keys):
    lines = []
    count = len(items)
    if count == 0:
        lines.append(
            section_header(name) + "   <span alpha='70%'>No active items</span>"
        )
    else:
        lines.append(section_header(name))
        for item in items:
            title = arr_display_title(item, title_keys)
            status = arr_display_status(item)
            lines.append(item_line(title, status))
    return lines


def sonarr_title(item):
    series = item.get("series", {}).get("title", "")
    ep = item.get("episode", {})
    s = ep.get("seasonNumber")
    e = ep.get("episodeNumber")
    ep_title = ep.get("title", "")
    if series and s is not None and e is not None:
        title = f"{series}  S{s:02d}E{e:02d}"
        if ep_title:
            title += f"  {ep_title}"
        return title
    return arr_display_title(item, ["series.title", "title"])


def lidarr_title(item):
    artist = item.get("artist", {}).get("artistName", "")
    album = item.get("album", {})
    album_title = album.get("title", "")
    year = (album.get("releaseDate") or "")[:4]
    if artist and album_title:
        title = f"{artist} – {album_title}"
        if year:
            title += f" ({year})"
        return title
    return arr_display_title(item, ["artist.artistName", "album.title", "title"])


def build_tooltip_sonarr(items):
    lines = []
    if not items:
        lines.append(
            section_header("Sonarr") + "   <span alpha='70%'>No active items</span>"
        )
        return lines
    lines.append(section_header("Sonarr"))
    for item in items:
        lines.append(item_line(sonarr_title(item), arr_display_status(item)))
    return lines


def build_tooltip_lidarr(items):
    lines = []
    if not items:
        lines.append(
            section_header("Lidarr") + "   <span alpha='70%'>No active items</span>"
        )
        return lines
    lines.append(section_header("Lidarr"))
    for item in items:
        lines.append(item_line(lidarr_title(item), arr_display_status(item)))
    return lines


# ── Structured collection ─────────────────────────────────────────────────────
#
# One fetch pass feeds both output modes: the Waybar text/tooltip payload and
# the structured report (`--json`) that richer frontends such as the Omarchy
# bar panel render themselves.

SERVICES = [
    ("qbittorrent", "qBittorrent"),
    ("sabnzbd", "SABnzbd"),
    ("radarr", "Radarr"),
    ("sonarr", "Sonarr"),
    ("lidarr", "Lidarr"),
]

SEPARATOR = "\n<span alpha='40%'>────────────────────────────────</span>\n"


class ServiceError(Exception):
    """A service answered, but said no — reported without the 'error:' prefix."""


def percent_of(done, total):
    try:
        total = float(total)
        done = float(done)
    except (TypeError, ValueError):
        return None
    if total <= 0:
        return None
    return max(0, min(100, int(done / total * 100)))


def arr_percent(item):
    size = item.get("size")
    left = item.get("sizeleft")
    if size is None or left is None:
        return None
    try:
        return percent_of(float(size) - float(left), size)
    except (TypeError, ValueError):
        return None


def make_item(title, status, percent=None, eta="", detail=""):
    return {
        "title": title,
        "status": status,
        "percent": percent,
        "eta": eta,
        "detail": detail,
    }


def qb_items(result):
    return [
        make_item(
            t.get("name", "Unknown"),
            "Downloading",
            percent_of(t.get("progress", 0), 1),
            format_eta_seconds(t.get("eta", -1)),
            f"↓ {format_speed(t.get('dlspeed', 0))}",
        )
        for t in result["active"]
    ]


def sab_items(result):
    items = []
    for slot in result["active"]:
        raw_pct = str(slot.get("percentage", "")).strip()
        timeleft = slot.get("timeleft", "")
        items.append(
            make_item(
                slot.get("filename", "Unknown"),
                slot.get("status") or "Downloading",
                int(raw_pct) if raw_pct.isdigit() else None,
                "" if timeleft in ("", "0:00:00") else timeleft,
            )
        )
    return items


def arr_state(item):
    """Bare state label. The Waybar tooltip wants progress folded into the
    status string; a frontend that draws its own meter wants just the word."""
    state = (item.get("trackedDownloadState") or "").lower()
    dl_status = (item.get("trackedDownloadStatus") or "").lower()
    if state == "downloading":
        return "Downloading"
    if state == "importpending":
        return "Importing"
    if dl_status == "warning":
        return "Stalled"
    return (item.get("status") or "").capitalize()


def arr_items(items, title_fn):
    return [
        make_item(
            title_fn(item),
            arr_state(item),
            arr_percent(item),
            format_eta_timestr(item.get("timeleft", "")),
        )
        for item in items
    ]


def service_url(cfg, section):
    return get(cfg, section, "webui_url") or get(cfg, section, "url")


def new_service(cfg, section, name):
    return {
        "id": section,
        "name": name,
        "url": service_url(cfg, section),
        "error": None,
        "dlSpeed": 0.0,
        "upSpeed": 0.0,
        "activeCount": 0,
        "summary": "",
        "items": [],
        "tooltip": [],
    }


def collect_qbittorrent(cfg, service):
    result, err = fetch_qbittorrent(cfg)
    if err:
        raise ServiceError(err)
    service["dlSpeed"] = result["dl_speed"]
    service["upSpeed"] = result["up_speed"]
    service["activeCount"] = len(result["active"])
    service["items"] = qb_items(result)
    service["summary"] = (
        f"↓ {format_speed(result['dl_speed'])}   ↑ {format_speed(result['up_speed'])}"
    )
    service["tooltip"] = build_tooltip_qbittorrent(result)


def collect_sabnzbd(cfg, service):
    result, err = fetch_sabnzbd(cfg)
    if err:
        raise ServiceError(err)
    service["dlSpeed"] = result["dl_speed"]
    service["activeCount"] = len(result["active"])
    service["items"] = sab_items(result)
    service["summary"] = f"↓ {format_speed(result['dl_speed'])}"
    service["tooltip"] = build_tooltip_sabnzbd(result)


def collect_radarr(cfg, service):
    items, err = fetch_arr_queue(
        get(cfg, "radarr", "url"), get(cfg, "radarr", "api_key"), "includeMovie=true"
    )
    if err:
        raise ServiceError(err)
    service["activeCount"] = len(items)
    service["items"] = arr_items(
        items, lambda item: arr_display_title(item, ["movie.title", "title"])
    )
    service["tooltip"] = build_tooltip_arr("Radarr", items, ["movie.title", "title"])


def collect_sonarr(cfg, service):
    items, err = fetch_arr_queue(
        get(cfg, "sonarr", "url"),
        get(cfg, "sonarr", "api_key"),
        "includeSeries=true&includeEpisode=true",
    )
    if err:
        raise ServiceError(err)
    service["activeCount"] = len(items)
    service["items"] = arr_items(items, sonarr_title)
    service["tooltip"] = build_tooltip_sonarr(items)


def collect_lidarr(cfg, service):
    items, err = fetch_lidarr_queue(
        get(cfg, "lidarr", "url"), get(cfg, "lidarr", "api_key")
    )
    if err:
        raise ServiceError(err)
    service["activeCount"] = len(items)
    service["items"] = arr_items(items, lidarr_title)
    service["tooltip"] = build_tooltip_lidarr(items)


COLLECTORS = {
    "qbittorrent": collect_qbittorrent,
    "sabnzbd": collect_sabnzbd,
    "radarr": collect_radarr,
    "sonarr": collect_sonarr,
    "lidarr": collect_lidarr,
}


def gather(cfg):
    """Fetch every enabled service. One bad service never sinks the others."""
    services = []
    for section, name in SERVICES:
        if not enabled(cfg, section):
            continue
        service = new_service(cfg, section, name)
        try:
            COLLECTORS[section](cfg, service)
        except ServiceError as e:
            service["error"] = str(e)
        except Exception as e:
            service["error"] = f"error: {e}"
        if service["error"]:
            service["tooltip"] = [
                section_header(name)
                + f"   <span color='#f38ba8'>{pango_escape(service['error'])}</span>"
            ]
        services.append(service)
    return services


def build_report(services):
    """Structured output for frontends that draw their own UI."""
    return {
        "schema": 1,
        "generatedAt": int(time.time()),
        "totals": {
            "dlSpeed": sum(s["dlSpeed"] for s in services),
            "upSpeed": sum(s["upSpeed"] for s in services),
            "activeCount": sum(s["activeCount"] for s in services),
            "hasErrors": any(s["error"] for s in services),
        },
        "services": [
            {key: value for key, value in s.items() if key != "tooltip"}
            for s in services
        ],
    }


def build_waybar(services):
    """Waybar JSON: bar text, Pango tooltip, CSS class."""
    total_dl_speed = sum(s["dlSpeed"] for s in services)
    total_active = sum(s["activeCount"] for s in services)
    has_errors = any(s["error"] for s in services)

    if total_active > 0:
        text = f"↓ {format_speed(total_dl_speed)}  ≡ {total_active}"
        css_class = "downloading"
    elif has_errors:
        text = "⚠"
        css_class = "error"
    else:
        text = ""
        css_class = "idle"

    sections = [s["tooltip"] for s in services if s["tooltip"]]
    tooltip = (
        SEPARATOR.join("\n".join(section) for section in sections)
        if sections
        else "All idle"
    )
    return {"text": text, "tooltip": tooltip, "class": css_class}


# ── Main ──────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="Report download client and *arr activity."
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="print the structured report instead of Waybar JSON",
    )
    args = parser.parse_args()

    cfg = load_config()
    services = gather(cfg)

    if args.json:
        print(json.dumps(build_report(services)), flush=True)
    else:
        print(json.dumps(build_waybar(services)), flush=True)


if __name__ == "__main__":
    main()
