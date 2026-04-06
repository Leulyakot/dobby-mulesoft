"""
End-to-end tests for dobby_server.py.

Spins up the real ThreadedServer on a random port, exercises every API
endpoint over HTTP, and tears the server down afterwards.  No mocks.
"""

import json
import os
import sys
import tempfile
import threading
import time
import unittest
import urllib.request
import urllib.error
from pathlib import Path

# Make sure we can import the server module directly
sys.path.insert(0, str(Path(__file__).parent.parent))

import dobby_server


# ── Helpers ──────────────────────────────────────────────────────────────────

def _start_server(project_path=None):
    """Start a ThreadedServer on an OS-assigned port and return (server, base_url)."""
    # Reset global state between tests
    dobby_server.project_path = project_path
    dobby_server.dobby_process = None

    server = dobby_server.ThreadedServer(("127.0.0.1", 0), dobby_server.DobbyHandler)
    port = server.server_address[1]
    t = threading.Thread(target=server.serve_forever)
    t.daemon = True
    t.start()
    return server, f"http://127.0.0.1:{port}"


def _get(base_url, path):
    with urllib.request.urlopen(f"{base_url}{path}") as r:
        return r.status, json.loads(r.read())


def _post(base_url, path, body=None):
    data = json.dumps(body or {}).encode()
    req = urllib.request.Request(
        f"{base_url}{path}",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def _make_dobby_project(tmp_dir):
    """Create a minimal .dobby project structure inside tmp_dir."""
    dobby = Path(tmp_dir) / ".dobby"
    logs = dobby / "house-elf-magic"
    logs.mkdir(parents=True)
    (dobby / "blueprints").mkdir()
    (dobby / "sock-drawer").mkdir()

    (dobby / "MASTER_ORDERS.md").write_text("# Orders\n\n- [ ] Task one\n- [ ] Task two\n")
    (dobby / "@magic_plan.md").write_text("# Plan\n\n- [x] Done task\n- [ ] Pending task\n")
    (dobby / "house-elf-magic" / "dobby.log").write_text(
        "[2024-01-01 00:00:00] [INFO] Dobby started\n"
        "[2024-01-01 00:00:01] [INFO] Loop 1\n"
    )
    (dobby / "house-elf-magic" / "dobby_status.json").write_text(json.dumps({
        "dobby_status": "working",
        "loop_count": 3,
        "max_loops": 100,
        "api_calls": 3,
        "completion_percentage": 50,
        "current_task": "Building flows",
        "circuit_breaker": "closed",
        "completion_signals": 0,
    }))
    return str(tmp_dir)


# ── Test Cases ────────────────────────────────────────────────────────────────

class TestHelperFunctions(unittest.TestCase):
    """Unit tests for module-level helper functions."""

    def test_read_file_safe_missing(self):
        self.assertEqual(dobby_server.read_file_safe("/nonexistent/path.txt"), "")

    def test_read_file_safe_existing(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
            f.write("hello dobby")
            name = f.name
        try:
            self.assertEqual(dobby_server.read_file_safe(name), "hello dobby")
        finally:
            os.unlink(name)

    def test_read_json_safe_missing(self):
        self.assertEqual(dobby_server.read_json_safe("/nonexistent.json"), {})

    def test_read_json_safe_valid(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump({"key": "value"}, f)
            name = f.name
        try:
            self.assertEqual(dobby_server.read_json_safe(name), {"key": "value"})
        finally:
            os.unlink(name)

    def test_read_json_safe_invalid(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            f.write("not json {{{")
            name = f.name
        try:
            self.assertEqual(dobby_server.read_json_safe(name), {})
        finally:
            os.unlink(name)

    def test_resolve_project_file_no_project(self):
        dobby_server.project_path = None
        self.assertIsNone(dobby_server.resolve_project_file("some/file"))

    def test_resolve_project_file_with_project(self):
        dobby_server.project_path = "/my/project"
        result = dobby_server.resolve_project_file(".dobby/status.json")
        self.assertEqual(result, "/my/project/.dobby/status.json")
        dobby_server.project_path = None


class TestStatusEndpoint(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        _make_dobby_project(self.tmp)
        self.server, self.base = _start_server(project_path=self.tmp)

    def tearDown(self):
        self.server.shutdown()

    def test_status_returns_200(self):
        status, body = _get(self.base, "/api/status")
        self.assertEqual(status, 200)

    def test_status_has_required_fields(self):
        _, body = _get(self.base, "/api/status")
        for field in ("status", "loop", "max_loops", "api_calls", "tasks_complete",
                      "tasks_total", "progress", "project_path"):
            self.assertIn(field, body, f"missing field: {field}")

    def test_status_maps_dobby_status_key(self):
        _, body = _get(self.base, "/api/status")
        # dobby_loop.sh writes "dobby_status"; the server should remap it to "status"
        self.assertNotIn("dobby_status", body)
        self.assertEqual(body["status"], "working")

    def test_status_progress_calculation(self):
        # Plan has 1 done + 1 pending → 50 %
        _, body = _get(self.base, "/api/status")
        self.assertEqual(body["tasks_complete"], 1)
        self.assertEqual(body["tasks_total"], 2)
        self.assertEqual(body["progress"], 50)

    def test_status_no_project(self):
        server, base = _start_server(project_path=None)
        try:
            _, body = _get(base, "/api/status")
            self.assertEqual(body["status"], "idle")
            self.assertEqual(body["project_path"], "")
        finally:
            server.shutdown()


class TestLogsEndpoint(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        _make_dobby_project(self.tmp)
        self.server, self.base = _start_server(project_path=self.tmp)

    def tearDown(self):
        self.server.shutdown()

    def test_logs_returns_list(self):
        _, body = _get(self.base, "/api/logs")
        self.assertIn("lines", body)
        self.assertIsInstance(body["lines"], list)

    def test_logs_content(self):
        _, body = _get(self.base, "/api/logs")
        joined = "\n".join(body["lines"])
        self.assertIn("Dobby started", joined)

    def test_logs_capped_at_200(self):
        # Write 300 lines to the log
        log_path = Path(self.tmp) / ".dobby/house-elf-magic/dobby.log"
        log_path.write_text("\n".join(f"line {i}" for i in range(300)) + "\n")
        _, body = _get(self.base, "/api/logs")
        self.assertLessEqual(len(body["lines"]), 200)

    def test_logs_empty_when_no_project(self):
        server, base = _start_server(project_path=None)
        try:
            _, body = _get(base, "/api/logs")
            self.assertEqual(body["lines"], [])
        finally:
            server.shutdown()


class TestOrdersEndpoint(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        _make_dobby_project(self.tmp)
        self.server, self.base = _start_server(project_path=self.tmp)

    def tearDown(self):
        self.server.shutdown()

    def test_get_orders(self):
        _, body = _get(self.base, "/api/orders")
        self.assertIn("content", body)
        self.assertIn("Task one", body["content"])

    def test_save_and_reload_orders(self):
        new_content = "# New Orders\n\nBuild something great.\n"
        status, body = _post(self.base, "/api/orders", {"content": new_content})
        self.assertEqual(status, 200)
        self.assertTrue(body["ok"])

        _, reloaded = _get(self.base, "/api/orders")
        self.assertEqual(reloaded["content"], new_content)

    def test_save_orders_no_project(self):
        server, base = _start_server(project_path=None)
        try:
            status, body = _post(base, "/api/orders", {"content": "hi"})
            self.assertEqual(status, 400)
            self.assertFalse(body["ok"])
        finally:
            server.shutdown()


class TestPlanEndpoint(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        _make_dobby_project(self.tmp)
        self.server, self.base = _start_server(project_path=self.tmp)

    def tearDown(self):
        self.server.shutdown()

    def test_get_plan(self):
        _, body = _get(self.base, "/api/plan")
        self.assertIn("content", body)
        self.assertIn("Done task", body["content"])

    def test_plan_empty_when_no_project(self):
        server, base = _start_server(project_path=None)
        try:
            _, body = _get(base, "/api/plan")
            self.assertEqual(body["content"], "")
        finally:
            server.shutdown()


class TestConfigEndpoint(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()

    def test_config_returns_fields(self):
        _, body = _get(self.base, "/api/config")
        self.assertIn("project_path", body)
        self.assertIn("server_dir", body)
        self.assertIn("dobby_home", body)


class TestLoadProjectEndpoint(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()
        dobby_server.project_path = None

    def test_load_existing_dobby_project(self):
        tmp = tempfile.mkdtemp()
        _make_dobby_project(tmp)
        status, body = _post(self.base, "/api/load", {"project_path": tmp})
        self.assertEqual(status, 200)
        self.assertTrue(body["ok"])
        self.assertEqual(body["project_path"], os.path.realpath(tmp))

    def test_load_creates_dobby_structure(self):
        tmp = tempfile.mkdtemp()
        new_project = os.path.join(tmp, "fresh-project")
        status, body = _post(self.base, "/api/load", {"project_path": new_project})
        self.assertEqual(status, 200)
        self.assertTrue(body["ok"])
        self.assertTrue(os.path.isdir(os.path.join(new_project, ".dobby")))
        self.assertTrue(os.path.isfile(os.path.join(new_project, ".dobby", "MASTER_ORDERS.md")))

    def test_load_empty_path_returns_400(self):
        status, body = _post(self.base, "/api/load", {"project_path": ""})
        self.assertEqual(status, 400)
        self.assertFalse(body["ok"])

    def test_load_missing_body_returns_400(self):
        status, body = _post(self.base, "/api/load", {})
        self.assertEqual(status, 400)
        self.assertFalse(body["ok"])


class TestStartEndpoint(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()
        dobby_server.project_path = None
        dobby_server.dobby_process = None

    def test_start_without_project_path(self):
        status, body = _post(self.base, "/api/start", {})
        self.assertEqual(status, 400)
        self.assertFalse(body["ok"])

    def test_start_without_dobby_dir(self):
        tmp = tempfile.mkdtemp()
        status, body = _post(self.base, "/api/start", {"project_path": tmp})
        self.assertEqual(status, 400)
        self.assertFalse(body["ok"])
        self.assertIn(".dobby", body["error"])


class TestStopEndpoint(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()
        dobby_server.dobby_process = None

    def test_stop_when_not_running(self):
        status, body = _post(self.base, "/api/stop", {})
        self.assertEqual(status, 400)
        self.assertFalse(body["ok"])
        self.assertIn("not running", body["error"])


class TestRequestBodyLimit(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()

    def test_oversized_body_returns_413(self):
        # Claim Content-Length > 10 MB
        oversized = 11 * 1024 * 1024
        req = urllib.request.Request(
            f"{self.base}/api/orders",
            data=b"x" * 100,  # actual data doesn't matter; header is checked first
            headers={
                "Content-Type": "application/json",
                "Content-Length": str(oversized),
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req) as r:
                status = r.status
                body = json.loads(r.read())
        except urllib.error.HTTPError as e:
            status = e.code
            body = json.loads(e.read())
        self.assertEqual(status, 413)
        self.assertFalse(body["ok"])


class TestCORSHeaders(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()

    def test_options_preflight(self):
        req = urllib.request.Request(
            f"{self.base}/api/status",
            method="OPTIONS",
        )
        with urllib.request.urlopen(req) as r:
            self.assertEqual(r.status, 204)

    def test_json_response_has_cors_header(self):
        req = urllib.request.Request(f"{self.base}/api/status")
        with urllib.request.urlopen(req) as r:
            self.assertEqual(r.headers.get("Access-Control-Allow-Origin"), "*")


class TestUnknownRoutes(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()

    def test_unknown_get_returns_404(self):
        req = urllib.request.Request(f"{self.base}/api/nonexistent")
        try:
            with urllib.request.urlopen(req):
                pass
            self.fail("Expected 404")
        except urllib.error.HTTPError as e:
            self.assertEqual(e.code, 404)

    def test_unknown_post_returns_404(self):
        req = urllib.request.Request(
            f"{self.base}/api/nonexistent",
            data=b"{}",
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req):
                pass
            self.fail("Expected 404")
        except urllib.error.HTTPError as e:
            self.assertEqual(e.code, 404)


class TestUIFileServing(unittest.TestCase):

    def setUp(self):
        self.server, self.base = _start_server()

    def tearDown(self):
        self.server.shutdown()

    def test_root_returns_html(self):
        ui_path = Path(dobby_server.server_dir) / "ui" / "index.html"
        if not ui_path.exists():
            self.skipTest("ui/index.html not present")
        with urllib.request.urlopen(f"{self.base}/") as r:
            self.assertEqual(r.status, 200)
            ct = r.headers.get("Content-Type", "")
            self.assertIn("text/html", ct)


if __name__ == "__main__":
    unittest.main(verbosity=2)
