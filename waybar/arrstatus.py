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

import configparser
import http.cookiejar
import json
import sys
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
#       "speed":      str,   # e.g. "1234.5 KB" (already in KB/s, not bytes)
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
    speed_str = queue.get("speed", "0")
    try:
        speed_kbps = float(speed_str.split()[0]) if speed_str else 0
    except (ValueError, IndexError):
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
        item_line(f"↓ {format_speed(dl)}", f"{dl_count} {'torrent' if dl_count == 1 else 'torrents'}"),
        item_line(f"↑ {format_speed(up)}", f"{up_count} {'torrent' if up_count == 1 else 'torrents'}"),
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


def build_tooltip_sonarr(items):
    lines = []
    if not items:
        lines.append(
            section_header("Sonarr") + "   <span alpha='70%'>No active items</span>"
        )
        return lines
    lines.append(section_header("Sonarr"))
    for item in items:
        series = item.get("series", {}).get("title", "")
        ep = item.get("episode", {})
        s = ep.get("seasonNumber")
        e = ep.get("episodeNumber")
        ep_title = ep.get("title", "")
        if series and s is not None and e is not None:
            title = f"{series}  S{s:02d}E{e:02d}"
            if ep_title:
                title += f"  {ep_title}"
        else:
            title = arr_display_title(item, ["series.title", "title"])
        lines.append(item_line(title, arr_display_status(item)))
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
        artist = item.get("artist", {}).get("artistName", "")
        album = item.get("album", {})
        album_title = album.get("title", "")
        year = (album.get("releaseDate") or "")[:4]
        if artist and album_title:
            title = f"{artist} – {album_title}"
            if year:
                title += f" ({year})"
        else:
            title = arr_display_title(
                item, ["artist.artistName", "album.title", "title"]
            )
        lines.append(item_line(title, arr_display_status(item)))
    return lines


# ── Main ──────────────────────────────────────────────────────────────────────


def main():
    cfg = load_config()

    total_dl_speed = 0.0
    total_active = 0
    tooltip_sections = []
    has_errors = False

    # qBittorrent
    if enabled(cfg, "qbittorrent"):
        try:
            result, err = fetch_qbittorrent(cfg)
            if err:
                tooltip_sections.append(
                    [
                        section_header("qBittorrent")
                        + f"   <span color='#f38ba8'>{err}</span>"
                    ]
                )
                has_errors = True
            else:
                total_dl_speed += result["dl_speed"]
                total_active += len(result["active"])
                tooltip_sections.append(build_tooltip_qbittorrent(result))
        except Exception as e:
            tooltip_sections.append(
                [
                    section_header("qBittorrent")
                    + f"   <span color='#f38ba8'>error: {pango_escape(str(e))}</span>"
                ]
            )
            has_errors = True

    # SABnzbd
    if enabled(cfg, "sabnzbd"):
        try:
            result, err = fetch_sabnzbd(cfg)
            if err:
                tooltip_sections.append(
                    [
                        section_header("SABnzbd")
                        + f"   <span color='#f38ba8'>{err}</span>"
                    ]
                )
                has_errors = True
            else:
                total_dl_speed += result["dl_speed"]
                total_active += len(result["active"])
                tooltip_sections.append(build_tooltip_sabnzbd(result))
        except Exception as e:
            tooltip_sections.append(
                [
                    section_header("SABnzbd")
                    + f"   <span color='#f38ba8'>error: {pango_escape(str(e))}</span>"
                ]
            )
            has_errors = True

    # Radarr
    if enabled(cfg, "radarr"):
        try:
            items, err = fetch_arr_queue(
                get(cfg, "radarr", "url"),
                get(cfg, "radarr", "api_key"),
                "includeMovie=true",
            )
            if err:
                tooltip_sections.append(
                    [
                        section_header("Radarr")
                        + f"   <span color='#f38ba8'>{err}</span>"
                    ]
                )
                has_errors = True
            else:
                total_active += len(items)
                tooltip_sections.append(
                    build_tooltip_arr("Radarr", items, ["movie.title", "title"])
                )
        except Exception as e:
            tooltip_sections.append(
                [
                    section_header("Radarr")
                    + f"   <span color='#f38ba8'>error: {pango_escape(str(e))}</span>"
                ]
            )
            has_errors = True

    # Sonarr
    if enabled(cfg, "sonarr"):
        try:
            items, err = fetch_arr_queue(
                get(cfg, "sonarr", "url"),
                get(cfg, "sonarr", "api_key"),
                "includeSeries=true&includeEpisode=true",
            )
            if err:
                tooltip_sections.append(
                    [
                        section_header("Sonarr")
                        + f"   <span color='#f38ba8'>{err}</span>"
                    ]
                )
                has_errors = True
            else:
                total_active += len(items)
                tooltip_sections.append(build_tooltip_sonarr(items))
        except Exception as e:
            tooltip_sections.append(
                [
                    section_header("Sonarr")
                    + f"   <span color='#f38ba8'>error: {pango_escape(str(e))}</span>"
                ]
            )
            has_errors = True

    # Lidarr
    if enabled(cfg, "lidarr"):
        try:
            items, err = fetch_lidarr_queue(
                get(cfg, "lidarr", "url"), get(cfg, "lidarr", "api_key")
            )
            if err:
                tooltip_sections.append(
                    [
                        section_header("Lidarr")
                        + f"   <span color='#f38ba8'>{err}</span>"
                    ]
                )
                has_errors = True
            else:
                total_active += len(items)
                tooltip_sections.append(build_tooltip_lidarr(items))
        except Exception as e:
            tooltip_sections.append(
                [
                    section_header("Lidarr")
                    + f"   <span color='#f38ba8'>error: {pango_escape(str(e))}</span>"
                ]
            )
            has_errors = True

    # Build output
    if total_active > 0:
        text = f"↓ {format_speed(total_dl_speed)}  ≡ {total_active}"
        css_class = "downloading"
    elif has_errors:
        text = "⚠"
        css_class = "error"
    else:
        text = ""
        css_class = "idle"

    sep = "\n<span alpha='40%'>────────────────────────────────</span>\n"
    tooltip = (
        sep.join("\n".join(sec) for sec in tooltip_sections)
        if tooltip_sections
        else "All idle"
    )

    print(
        json.dumps({"text": text, "tooltip": tooltip, "class": css_class}), flush=True
    )


if __name__ == "__main__":
    main()
