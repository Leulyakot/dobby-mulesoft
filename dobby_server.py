#!/usr/bin/env python3
"""
Dobby UI Server - Lightweight Python web server for the Dobby MuleSoft Elf.
Zero dependencies beyond Python 3 stdlib.
"""

import http.server
import json
import os
import signal
import subprocess
import sys
import threading
from pathlib import Path
from urllib.parse import urlparse

# ── Configuration ──
DEFAULT_PORT = 3131
DOBBY_DIR = ".dobby"
LOG_DIR = os.path.join(DOBBY_DIR, "house-elf-magic")
STATUS_FILE = os.path.join(DOBBY_DIR, "house-elf-magic", "dobby_status.json")
ORDERS_FILE = os.path.join(DOBBY_DIR, "MASTER_ORDERS.md")
PLAN_FILE = os.path.join(DOBBY_DIR, "@magic_plan.md")
LOG_FILE = os.path.join(DOBBY_DIR, "house-elf-magic", "dobby.log")

# ── State ──
project_path = None
dobby_process = None
server_dir = os.path.dirname(os.path.abspath(__file__))


def resolve_project_file(rel_path):
    """Resolve a file path relative to the active project."""
    if project_path:
        return os.path.join(project_path, rel_path)
    return None


def read_file_safe(path):
    """Read file contents, return empty string if not found."""
    try:
        if path and os.path.isfile(path):
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                return f.read()
    except Exception:
        pass
    return ""


def read_json_safe(path):
    """Read JSON file, return empty dict if not found."""
    content = read_file_safe(path)
    if content:
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            pass
    return {}


class DobbyHandler(http.server.BaseHTTPRequestHandler):
    """HTTP request handler for the Dobby UI API."""

    def log_message(self, format, *args):
        """Suppress default logging for cleaner output."""
        pass

    def send_json(self, data, status=200):
        """Send a JSON response."""
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def send_file(self, filepath, content_type):
        """Send a static file."""
        try:
            with open(filepath, "rb") as f:
                content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(content)))
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404)

    def read_body(self):
        """Read request body as JSON."""
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        raw = self.rfile.read(length)
        try:
            return json.loads(raw.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            return {}

    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        """Route GET requests."""
        path = urlparse(self.path).path

        if path == "/" or path == "/index.html":
            ui_path = os.path.join(server_dir, "ui", "index.html")
            self.send_file(ui_path, "text/html; charset=utf-8")

        elif path == "/api/status":
            self.handle_get_status()

        elif path == "/api/logs":
            self.handle_get_logs()

        elif path == "/api/orders":
            self.handle_get_orders()

        elif path == "/api/plan":
            self.handle_get_plan()

        elif path == "/api/config":
            self.handle_get_config()

        else:
            self.send_error(404)

    def do_POST(self):
        """Route POST requests."""
        path = urlparse(self.path).path

        if path == "/api/start":
            self.handle_start()

        elif path == "/api/stop":
            self.handle_stop()

        elif path == "/api/orders":
            self.handle_save_orders()

        elif path == "/api/load":
            self.handle_load_project()

        else:
            self.send_error(404)

    # ── API Handlers ──

    def handle_get_status(self):
        global project_path
        status_path = resolve_project_file(STATUS_FILE)
        data = read_json_safe(status_path) if status_path else {}

        # Enrich with computed fields
        plan_path = resolve_project_file(PLAN_FILE)
        plan_content = read_file_safe(plan_path)
        done = plan_content.count("[x]") + plan_content.count("[X]")
        total = done + plan_content.count("[ ]")

        data.setdefault("status", "idle")
        data.setdefault("loop", 0)
        data.setdefault("max_loops", 100)
        data.setdefault("api_calls", 0)
        data.setdefault("circuit_breaker", "--")
        data.setdefault("current_task", "")
        data["tasks_complete"] = done
        data["tasks_total"] = total
        data["progress"] = round((done / total) * 100) if total > 0 else 0
        data["project_path"] = project_path or ""

        # Check if process is still running
        if dobby_process and dobby_process.poll() is not None:
            data["status"] = "complete" if dobby_process.returncode == 0 else "error"

        self.send_json(data)

    def handle_get_logs(self):
        log_path = resolve_project_file(LOG_FILE)
        content = read_file_safe(log_path)
        lines = content.strip().split("\n") if content.strip() else []
        # Return last 200 lines
        self.send_json({"lines": lines[-200:]})

    def handle_get_orders(self):
        orders_path = resolve_project_file(ORDERS_FILE)
        content = read_file_safe(orders_path)
        self.send_json({"content": content})

    def handle_get_plan(self):
        plan_path = resolve_project_file(PLAN_FILE)
        content = read_file_safe(plan_path)
        self.send_json({"content": content})

    def handle_get_config(self):
        self.send_json({
            "project_path": project_path or "",
            "dobby_home": os.environ.get("DOBBY_HOME", ""),
            "server_dir": server_dir,
        })

    def handle_start(self):
        global project_path, dobby_process

        body = self.read_body()
        proj = body.get("project_path", "").strip()

        if not proj:
            self.send_json({"ok": False, "error": "No project path provided"}, 400)
            return

        proj = os.path.expanduser(proj)
        if not os.path.isabs(proj):
            proj = os.path.abspath(proj)

        dobby_dir = os.path.join(proj, DOBBY_DIR)
        if not os.path.isdir(dobby_dir):
            self.send_json({"ok": False, "error": f"No .dobby directory found in {proj}"}, 400)
            return

        if dobby_process and dobby_process.poll() is None:
            self.send_json({"ok": False, "error": "Dobby is already running"}, 409)
            return

        project_path = proj

        # Find dobby_loop.sh
        loop_script = None
        candidates = [
            os.path.join(server_dir, "dobby_loop.sh"),
            os.path.join(os.environ.get("DOBBY_HOME", ""), "dobby_loop.sh"),
            os.path.expanduser("~/.dobby/dobby_loop.sh"),
        ]
        for c in candidates:
            if os.path.isfile(c):
                loop_script = c
                break

        if not loop_script:
            self.send_json({"ok": False, "error": "Cannot find dobby_loop.sh"}, 500)
            return

        try:
            dobby_process = subprocess.Popen(
                ["bash", loop_script, "--snap"],
                cwd=project_path,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                preexec_fn=os.setsid,
            )
            self.send_json({"ok": True, "pid": dobby_process.pid})
        except Exception as e:
            self.send_json({"ok": False, "error": str(e)}, 500)

    def handle_stop(self):
        global dobby_process

        if not dobby_process or dobby_process.poll() is not None:
            self.send_json({"ok": False, "error": "Dobby is not running"}, 400)
            return

        try:
            os.killpg(os.getpgid(dobby_process.pid), signal.SIGTERM)
            dobby_process.wait(timeout=10)
        except Exception:
            try:
                os.killpg(os.getpgid(dobby_process.pid), signal.SIGKILL)
            except Exception:
                pass

        dobby_process = None
        self.send_json({"ok": True})

    def handle_load_project(self):
        global project_path

        body = self.read_body()
        proj = body.get("project_path", "").strip()

        if not proj:
            self.send_json({"ok": False, "error": "No project path provided"}, 400)
            return

        proj = os.path.expanduser(proj)
        if not os.path.isabs(proj):
            proj = os.path.abspath(proj)

        dobby_dir = os.path.join(proj, DOBBY_DIR)
        if not os.path.isdir(dobby_dir):
            self.send_json({"ok": False, "error": f"No .dobby directory found in {proj}"}, 400)
            return

        project_path = proj
        self.send_json({"ok": True, "project_path": project_path})

    def handle_save_orders(self):
        body = self.read_body()
        content = body.get("content", "")

        orders_path = resolve_project_file(ORDERS_FILE)
        if not orders_path:
            self.send_json({"ok": False, "error": "No project loaded. Click Load first."}, 400)
            return

        try:
            os.makedirs(os.path.dirname(orders_path), exist_ok=True)
            with open(orders_path, "w", encoding="utf-8") as f:
                f.write(content)
            self.send_json({"ok": True})
        except Exception as e:
            self.send_json({"ok": False, "error": str(e)}, 500)


class ThreadedServer(http.server.HTTPServer):
    """HTTP server that handles each request in a new thread."""
    allow_reuse_address = True

    def process_request(self, request, client_address):
        t = threading.Thread(target=self.process_request_thread, args=(request, client_address))
        t.daemon = True
        t.start()

    def process_request_thread(self, request, client_address):
        try:
            self.finish_request(request, client_address)
        except Exception:
            self.handle_error(request, client_address)
        finally:
            self.shutdown_request(request)


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    global project_path

    # Accept optional project path as second arg
    if len(sys.argv) > 2:
        p = os.path.expanduser(sys.argv[2])
        if os.path.isdir(os.path.join(p, DOBBY_DIR)):
            project_path = os.path.abspath(p)

    server = ThreadedServer(("0.0.0.0", port), DobbyHandler)

    print(f"""
\033[36m
    .---.
   | ^ ^ |   Dobby UI Server
   |  >  |   ───────────────
    \\___/    http://localhost:{port}
     |||
    /|||\\
\033[0m""")

    if project_path:
        print(f"  Project: {project_path}")
    print(f"  Press Ctrl+C to stop\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Dobby UI server stopped.")
        # Clean up dobby process if running
        if dobby_process and dobby_process.poll() is None:
            try:
                os.killpg(os.getpgid(dobby_process.pid), signal.SIGTERM)
            except Exception:
                pass
        server.shutdown()


if __name__ == "__main__":
    main()
