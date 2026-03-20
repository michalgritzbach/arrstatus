#!/usr/bin/env python3
"""
Tests for arrstatus.py waybar widget.
Run with: python3 -m pytest waybar/test_arrstatus.py
     or:  python3 waybar/test_arrstatus.py
"""

import configparser
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import arrstatus as arr


class TestFormatSpeed(unittest.TestCase):

    def test_bytes(self):
        self.assertEqual(arr.format_speed(0), "0 B/s")
        self.assertEqual(arr.format_speed(500), "500 B/s")
        self.assertEqual(arr.format_speed(1023), "1023 B/s")

    def test_kilobytes(self):
        self.assertEqual(arr.format_speed(1024), "1 KB/s")
        self.assertEqual(arr.format_speed(5120), "5 KB/s")
        self.assertEqual(arr.format_speed(102400), "100 KB/s")

    def test_megabytes(self):
        self.assertEqual(arr.format_speed(1_048_576), "1.0 MB/s")
        self.assertEqual(arr.format_speed(5_242_880), "5.0 MB/s")
        self.assertEqual(arr.format_speed(104_857_600), "100.0 MB/s")

    def test_gigabytes(self):
        self.assertEqual(arr.format_speed(1_073_741_824), "1.0 GB/s")
        self.assertEqual(arr.format_speed(5_368_709_120), "5.0 GB/s")


class TestFormatEtaSeconds(unittest.TestCase):

    def test_zero_returns_empty(self):
        self.assertEqual(arr.format_eta_seconds(0), "")

    def test_negative_returns_empty(self):
        self.assertEqual(arr.format_eta_seconds(-1), "")

    def test_too_large_returns_empty(self):
        self.assertEqual(arr.format_eta_seconds(8_640_001), "")

    def test_minutes(self):
        self.assertEqual(arr.format_eta_seconds(600), "10m")
        self.assertEqual(arr.format_eta_seconds(45 * 60), "45m")

    def test_hours(self):
        self.assertEqual(arr.format_eta_seconds(3600), "1h 0m")
        self.assertEqual(arr.format_eta_seconds(5400), "1h 30m")
        self.assertEqual(arr.format_eta_seconds(7200), "2h 0m")

    def test_days(self):
        self.assertEqual(arr.format_eta_seconds(86400), "1d 0h")
        self.assertEqual(arr.format_eta_seconds(86400 + 3600 * 6), "1d 6h")

    def test_less_than_one_minute(self):
        self.assertEqual(arr.format_eta_seconds(30), "<1m")


class TestFormatEtaTimestr(unittest.TestCase):

    def test_empty_string(self):
        self.assertEqual(arr.format_eta_timestr(""), "")

    def test_none(self):
        self.assertEqual(arr.format_eta_timestr(None), "")

    def test_hms_hours_and_minutes(self):
        self.assertEqual(arr.format_eta_timestr("02:30:00"), "2h 30m")

    def test_hms_minutes_only(self):
        self.assertEqual(arr.format_eta_timestr("00:45:00"), "45m")

    def test_hms_hours_zero_minutes(self):
        self.assertEqual(arr.format_eta_timestr("03:00:00"), "3h 0m")

    def test_with_days(self):
        self.assertEqual(arr.format_eta_timestr("63.06:58:33"), "63d 6h")
        self.assertEqual(arr.format_eta_timestr("1.12:00:00"), "1d 12h")

    def test_zero_time(self):
        self.assertEqual(arr.format_eta_timestr("00:00:00"), "<1m")

    def test_invalid_falls_back_to_original(self):
        result = arr.format_eta_timestr("not-a-time")
        self.assertEqual(result, "not-a-time")


class TestPangoEscape(unittest.TestCase):

    def test_no_special_chars(self):
        self.assertEqual(arr.pango_escape("hello world"), "hello world")

    def test_ampersand(self):
        self.assertEqual(arr.pango_escape("rock & roll"), "rock &amp; roll")

    def test_less_than(self):
        self.assertEqual(arr.pango_escape("a < b"), "a &lt; b")

    def test_greater_than(self):
        self.assertEqual(arr.pango_escape("a > b"), "a &gt; b")

    def test_all_special(self):
        self.assertEqual(arr.pango_escape("<b>bold & bright</b>"), "&lt;b&gt;bold &amp; bright&lt;/b&gt;")

    def test_empty(self):
        self.assertEqual(arr.pango_escape(""), "")


class TestArrIsActive(unittest.TestCase):

    def test_downloading(self):
        self.assertTrue(arr._arr_is_active({"trackedDownloadState": "downloading"}))

    def test_import_pending(self):
        self.assertTrue(arr._arr_is_active({"trackedDownloadState": "importPending"}))

    def test_warning_status(self):
        self.assertTrue(arr._arr_is_active({"trackedDownloadStatus": "warning"}))

    def test_completed_not_active(self):
        self.assertFalse(arr._arr_is_active({"trackedDownloadState": "imported", "trackedDownloadStatus": "ok"}))

    def test_empty_item_not_active(self):
        self.assertFalse(arr._arr_is_active({}))

    def test_none_values_not_active(self):
        self.assertFalse(arr._arr_is_active({"trackedDownloadState": None, "trackedDownloadStatus": None}))

    def test_case_insensitive(self):
        self.assertTrue(arr._arr_is_active({"trackedDownloadState": "DOWNLOADING"}))
        self.assertTrue(arr._arr_is_active({"trackedDownloadStatus": "WARNING"}))


class TestArrDisplayStatus(unittest.TestCase):

    def test_downloading_with_progress_and_eta(self):
        item = {
            "trackedDownloadState": "downloading",
            "size": 1_000_000, "sizeleft": 500_000,
            "timeleft": "01:30:00",
        }
        result = arr.arr_display_status(item)
        self.assertIn("Downloading", result)
        self.assertIn("50%", result)
        self.assertIn("1h 30m", result)

    def test_downloading_no_size(self):
        item = {"trackedDownloadState": "downloading"}
        self.assertEqual(arr.arr_display_status(item), "Downloading")

    def test_importing(self):
        item = {"trackedDownloadState": "importPending"}
        self.assertEqual(arr.arr_display_status(item), "Importing")

    def test_stalled(self):
        item = {"trackedDownloadStatus": "warning"}
        self.assertEqual(arr.arr_display_status(item), "Stalled")

    def test_other_status_capitalized(self):
        item = {"status": "queued", "trackedDownloadState": "", "trackedDownloadStatus": ""}
        self.assertEqual(arr.arr_display_status(item), "Queued")


class TestArrDisplayTitle(unittest.TestCase):

    def test_nested_key(self):
        item = {"movie": {"title": "The Matrix"}, "title": "The.Matrix.1999"}
        self.assertEqual(arr.arr_display_title(item, ["movie.title", "title"]), "The Matrix")

    def test_fallback_to_next_key(self):
        item = {"title": "The.Matrix.1999"}
        self.assertEqual(arr.arr_display_title(item, ["movie.title", "title"]), "The.Matrix.1999")

    def test_fallback_to_title_field(self):
        item = {"title": "Fallback.Title"}
        self.assertEqual(arr.arr_display_title(item, ["nonexistent"]), "Fallback.Title")

    def test_unknown_if_no_title(self):
        self.assertEqual(arr.arr_display_title({}, ["nonexistent"]), "Unknown")

    def test_skips_empty_string(self):
        item = {"movie": {"title": ""}, "title": "real.title"}
        self.assertEqual(arr.arr_display_title(item, ["movie.title", "title"]), "real.title")


class TestBuildTooltipQbittorrent(unittest.TestCase):

    def test_basic_output(self):
        result = {
            "dl_speed": 5_242_880, "up_speed": 1_048_576,
            "active": [{"name": "a", "dlspeed": 1000}],
            "uploading": [],
        }
        lines = arr.build_tooltip_qbittorrent(result)
        self.assertEqual(len(lines), 3)
        self.assertIn("qBittorrent", lines[0])
        self.assertIn("5.0 MB/s", lines[1])
        self.assertIn("1 torrent", lines[1])
        self.assertIn("0 torrents", lines[2])

    def test_plural_torrents(self):
        result = {
            "dl_speed": 0, "up_speed": 0,
            "active": [{"dlspeed": 1000}, {"dlspeed": 2000}],
            "uploading": [{"upspeed": 500}, {"upspeed": 600}, {"upspeed": 700}],
        }
        lines = arr.build_tooltip_qbittorrent(result)
        self.assertIn("2 torrents", lines[1])
        self.assertIn("3 torrents", lines[2])

    def test_zero_speeds(self):
        result = {"dl_speed": 0, "up_speed": 0, "active": [], "uploading": []}
        lines = arr.build_tooltip_qbittorrent(result)
        self.assertIn("0 B/s", lines[1])


class TestBuildTooltipSabnzbd(unittest.TestCase):

    def test_empty_queue(self):
        result = {"dl_speed": 0, "active": []}
        lines = arr.build_tooltip_sabnzbd(result)
        self.assertEqual(len(lines), 1)
        self.assertIn("SABnzbd", lines[0])
        self.assertIn("0 downloads", lines[0])

    def test_with_active_slots(self):
        result = {
            "dl_speed": 2_097_152,
            "active": [
                {"filename": "ubuntu.iso", "percentage": "45", "timeleft": "1:30:00"},
                {"filename": "debian.iso", "percentage": "80", "timeleft": "0:15:00"},
            ],
        }
        lines = arr.build_tooltip_sabnzbd(result)
        self.assertEqual(len(lines), 3)
        self.assertIn("2 downloads", lines[0])
        self.assertIn("ubuntu.iso", lines[1])
        self.assertIn("debian.iso", lines[2])

    def test_singular_download(self):
        result = {
            "dl_speed": 1024,
            "active": [{"filename": "file.nzb", "percentage": "10", "timeleft": "2:00:00"}],
        }
        lines = arr.build_tooltip_sabnzbd(result)
        self.assertIn("1 download", lines[0])
        self.assertNotIn("1 downloads", lines[0])


class TestBuildTooltipArr(unittest.TestCase):

    def test_empty_items(self):
        lines = arr.build_tooltip_arr("Radarr", [], ["movie.title"])
        self.assertEqual(len(lines), 1)
        self.assertIn("Radarr", lines[0])
        self.assertIn("No active items", lines[0])

    def test_with_items(self):
        items = [
            {
                "movie": {"title": "The Matrix"},
                "title": "The.Matrix.mkv",
                "trackedDownloadState": "downloading",
                "size": 2_000_000, "sizeleft": 1_000_000, "timeleft": "00:30:00",
            }
        ]
        lines = arr.build_tooltip_arr("Radarr", items, ["movie.title", "title"])
        self.assertEqual(len(lines), 2)
        self.assertIn("Radarr", lines[0])
        self.assertIn("The Matrix", lines[1])
        self.assertIn("50%", lines[1])


class TestBuildTooltipSonarr(unittest.TestCase):

    def test_empty(self):
        lines = arr.build_tooltip_sonarr([])
        self.assertEqual(len(lines), 1)
        self.assertIn("No active items", lines[0])

    def test_with_episode_and_title(self):
        item = {
            "series": {"title": "Breaking Bad"},
            "episode": {"seasonNumber": 1, "episodeNumber": 5, "title": "Gray Matter"},
            "trackedDownloadState": "downloading",
            "size": 1_000_000, "sizeleft": 0, "timeleft": "",
        }
        lines = arr.build_tooltip_sonarr([item])
        self.assertEqual(len(lines), 2)
        self.assertIn("Breaking Bad  S01E05  Gray Matter", lines[1])

    def test_with_episode_no_title(self):
        item = {
            "series": {"title": "Breaking Bad"},
            "episode": {"seasonNumber": 1, "episodeNumber": 5, "title": ""},
            "trackedDownloadState": "downloading",
            "size": None, "sizeleft": None, "timeleft": "",
        }
        lines = arr.build_tooltip_sonarr([item])
        self.assertIn("Breaking Bad  S01E05", lines[1])
        self.assertNotIn("  S01E05  ", lines[1].split("Breaking Bad  S01E05")[1] if "Breaking Bad  S01E05" in lines[1] else "x")

    def test_fallback_no_series(self):
        item = {
            "title": "Breaking.Bad.S01E05.mkv",
            "trackedDownloadState": "downloading",
        }
        lines = arr.build_tooltip_sonarr([item])
        self.assertIn("Breaking.Bad.S01E05.mkv", lines[1])


class TestBuildTooltipLidarr(unittest.TestCase):

    def test_empty(self):
        lines = arr.build_tooltip_lidarr([])
        self.assertEqual(len(lines), 1)
        self.assertIn("No active items", lines[0])

    def test_with_artist_album_and_year(self):
        item = {
            "artist": {"artistName": "Rush"},
            "album": {"title": "Signals", "releaseDate": "1982-09-09"},
            "trackedDownloadState": "downloading",
            "size": None, "sizeleft": None, "timeleft": "",
        }
        lines = arr.build_tooltip_lidarr([item])
        self.assertEqual(len(lines), 2)
        self.assertIn("Rush – Signals (1982)", lines[1])

    def test_with_artist_album_no_year(self):
        item = {
            "artist": {"artistName": "Rush"},
            "album": {"title": "Signals", "releaseDate": ""},
            "trackedDownloadState": "downloading",
        }
        lines = arr.build_tooltip_lidarr([item])
        self.assertIn("Rush – Signals", lines[1])
        self.assertNotIn("()", lines[1])

    def test_fallback_to_album_title(self):
        item = {
            "album": {"title": "Signals"},
            "title": "Rush.Signals.FLAC",
            "trackedDownloadState": "downloading",
        }
        lines = arr.build_tooltip_lidarr([item])
        self.assertIn("Signals", lines[1])

    def test_pango_escaping_in_title(self):
        item = {
            "artist": {"artistName": "AC/DC"},
            "album": {"title": "Back in Black & More", "releaseDate": "1980-07-25"},
            "trackedDownloadState": "importing",
        }
        lines = arr.build_tooltip_lidarr([item])
        self.assertIn("&amp;", lines[1])
        self.assertNotIn("Black & More", lines[1])  # raw & should be escaped


class TestConfigHelpers(unittest.TestCase):

    def _make_cfg(self, content):
        cfg = configparser.ConfigParser(default_section="__none__")
        cfg.read_string(content)
        return cfg

    def test_get_existing_key(self):
        cfg = self._make_cfg("[radarr]\nurl = http://localhost:7878\n")
        self.assertEqual(arr.get(cfg, "radarr", "url"), "http://localhost:7878")

    def test_get_missing_key_returns_fallback(self):
        cfg = self._make_cfg("[radarr]\n")
        self.assertEqual(arr.get(cfg, "radarr", "missing_key"), "")
        self.assertEqual(arr.get(cfg, "radarr", "missing_key", "default"), "default")

    def test_get_missing_section_returns_fallback(self):
        cfg = self._make_cfg("")
        self.assertEqual(arr.get(cfg, "nonexistent", "key"), "")

    def test_enabled_true(self):
        for val in ("true", "True", "TRUE", "yes", "1"):
            cfg = self._make_cfg(f"[radarr]\nenabled = {val}\n")
            self.assertTrue(arr.enabled(cfg, "radarr"), f"Expected True for '{val}'")

    def test_enabled_false(self):
        for val in ("false", "False", "no", "0"):
            cfg = self._make_cfg(f"[radarr]\nenabled = {val}\n")
            self.assertFalse(arr.enabled(cfg, "radarr"), f"Expected False for '{val}'")

    def test_enabled_missing_section(self):
        cfg = self._make_cfg("")
        self.assertFalse(arr.enabled(cfg, "radarr"))


class TestLoadConfig(unittest.TestCase):

    def test_creates_default_config_if_missing(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_path = os.path.join(tmpdir, "subdir", "arrstatus.conf")
            # Patch CONFIG_PATH temporarily
            original = arr.CONFIG_PATH
            arr.CONFIG_PATH = config_path
            try:
                cfg = arr.load_config()
                self.assertTrue(os.path.exists(config_path))
                self.assertFalse(arr.enabled(cfg, "qbittorrent"))
                self.assertFalse(arr.enabled(cfg, "radarr"))
            finally:
                arr.CONFIG_PATH = original

    def test_reads_existing_config(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".conf", delete=False) as f:
            f.write("[radarr]\nenabled = true\nurl = http://localhost:7878\napi_key = testkey\n")
            path = f.name
        try:
            original = arr.CONFIG_PATH
            arr.CONFIG_PATH = path
            try:
                cfg = arr.load_config()
                self.assertTrue(arr.enabled(cfg, "radarr"))
                self.assertEqual(arr.get(cfg, "radarr", "api_key"), "testkey")
            finally:
                arr.CONFIG_PATH = original
        finally:
            os.unlink(path)


if __name__ == "__main__":
    unittest.main()
