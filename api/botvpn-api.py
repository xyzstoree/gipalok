#!/usr/bin/env python3
# ============================================================================
# v7fix — BotVPN API
# Hardening vs gipalok:
#   - Default bind 127.0.0.1 (override with V7FIX_API_HOST=0.0.0.0)
#   - Token via header only — query string `?auth=` removed
#   - POST-only for endpoints that take password (createssh)
#   - shutil.which("xray") instead of hardcoded /usr/local/bin/xray
#   - Atomic config write with xray test still preserved
# ============================================================================
import base64
import json
import os
import re
import shutil
import subprocess
import uuid
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse


HOST = os.environ.get("V7FIX_API_HOST", "127.0.0.1")
PORT = int(os.environ.get("V7FIX_API_PORT", "5889"))

XRAY_CONFIG = "/etc/xray/config.json"
DOMAIN_FILE = "/etc/xray/domain"
API_TOKEN_FILE = "/etc/Anggun/api-token"
QUEUE_DIR = "/etc/Anggun/Queue"
XRAY_BIN = shutil.which("xray") or "/usr/local/bin/xray"


def sh(cmd, check=False):
    return subprocess.run(
        cmd, shell=True, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=check,
    )


def read_file(path, default=""):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return default


def write_file(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(str(data))


def get_domain():
    domain = read_file(DOMAIN_FILE) or read_file("/root/domain")
    if domain:
        return domain
    ip = sh("curl -sS --max-time 3 ipv4.icanhazip.com || curl -sS --max-time 3 ifconfig.me").stdout.strip()
    return ip or "domain.com"


def get_token():
    token = read_file(API_TOKEN_FILE)
    if not token:
        token = str(uuid.uuid4())
        write_file(API_TOKEN_FILE, token)
        os.chmod(API_TOKEN_FILE, 0o600)
    return token


def response(handler, code, payload):
    body = json.dumps(payload, indent=2)
    handler.send_response(code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("X-Content-Type-Options", "nosniff")
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.send_header("Content-Length", str(len(body.encode())))
    handler.end_headers()
    handler.wfile.write(body.encode())


def parse_request(handler):
    """Returns (path, params, is_post). Token must come via header for POST.
    For GET, query params are accepted (but token via query is REJECTED below).
    """
    parsed = urlparse(handler.path)
    params = {k: v[0] for k, v in parse_qs(parsed.query).items()}
    is_post = handler.command == "POST"

    if is_post:
        length = int(handler.headers.get("Content-Length", "0") or 0)
        if length > 0:
            raw = handler.rfile.read(length).decode(errors="ignore")
            try:
                data = json.loads(raw)
                if isinstance(data, dict):
                    params.update({k: str(v) for k, v in data.items()})
            except Exception:
                post_params = {k: v[0] for k, v in parse_qs(raw).items()}
                params.update(post_params)

    return parsed.path.strip("/").lower(), params, is_post


def auth_ok(headers):
    """Token MUST come from header — never from query string.
    Accepts X-API-Key or Authorization: Bearer <token>.
    """
    supplied = (
        headers.get("X-API-Key")
        or headers.get("Authorization", "").replace("Bearer ", "").strip()
    )
    return supplied and supplied == get_token()


def clean_username(user):
    user = (user or "").strip()
    if not re.match(r"^[a-zA-Z0-9_][a-zA-Z0-9_-]{1,31}$", user):
        raise ValueError("Username hanya boleh huruf/angka/_/-, panjang 2-32")
    return user


def int_param(params, key, default=0, min_value=0):
    try:
        val = int(str(params.get(key, default)).strip())
    except Exception:
        val = default
    if val < min_value:
        val = min_value
    return val


def exp_date(days):
    days = int(days or 1)
    if days < 1:
        days = 1
    return (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")


def load_config():
    with open(XRAY_CONFIG, "r") as f:
        return json.load(f)


def save_config(cfg):
    tmp = XRAY_CONFIG + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cfg, f, indent=2)

    test = sh(f"{XRAY_BIN} test -config {tmp}")
    if test.returncode != 0:
        os.remove(tmp)
        raise RuntimeError("Xray config test gagal: " + (test.stderr or test.stdout))

    os.replace(tmp, XRAY_CONFIG)


def ensure_metadata(cfg, proto, user, meta):
    cfg.setdefault("_metadata", {}).setdefault(proto, {})[user] = meta


def add_client_to_tag(cfg, tag, client, user):
    found = False
    for inbound in cfg.get("inbounds", []):
        if inbound.get("tag") == tag:
            found = True
            inbound.setdefault("settings", {}).setdefault("clients", [])
            for c in inbound["settings"]["clients"]:
                if c.get("email") == user:
                    raise ValueError(f"User {user} sudah ada di inbound {tag}")
            inbound["settings"]["clients"].append(client)
    return found


def restart_xray():
    sh("systemctl restart xray", check=False)


def save_limit(proto, user, iplimit, quota):
    ip_dir = os.path.join(QUEUE_DIR, proto, "ip")
    quota_dir = os.path.join(QUEUE_DIR, proto, "quota")
    os.makedirs(ip_dir, exist_ok=True)
    os.makedirs(quota_dir, exist_ok=True)
    if int(iplimit) > 0:
        write_file(os.path.join(ip_dir, user), str(iplimit))
    if int(quota) > 0:
        write_file(os.path.join(quota_dir, user), str(quota))


def make_vmess_link(domain, user, uid, port, tls=True):
    data = {
        "v": "2", "ps": user, "add": domain, "port": str(port),
        "id": uid, "aid": "0", "net": "ws", "type": "none",
        "host": domain, "path": "/vmess",
        "tls": "tls" if tls else "", "sni": domain if tls else "",
    }
    raw = json.dumps(data, separators=(",", ":")).encode()
    return "vmess://" + base64.b64encode(raw).decode()


def create_ssh(params):
    user = clean_username(params.get("user") or params.get("username"))
    password = params.get("password") or params.get("pass") or ""
    days = int_param(params, "exp", 1, 1)
    iplimit = int_param(params, "iplimit", 2, 0)

    if not password:
        raise ValueError("Password tidak boleh kosong")

    expired = exp_date(days)

    if sh(f"id {user}").returncode == 0:
        sh(f"usermod -e {expired} -s /bin/bash {user}", check=True)
    else:
        sh(f"useradd -e {expired} -s /bin/bash -m {user}", check=True)

    p = subprocess.run(
        ["chpasswd"],
        input=f"{user}:{password}\n",
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if p.returncode != 0:
        raise RuntimeError(p.stderr)

    os.makedirs(f"{QUEUE_DIR}/ssh/ip", exist_ok=True)
    if iplimit > 0:
        write_file(f"{QUEUE_DIR}/ssh/ip/{user}", str(iplimit))

    domain = get_domain()
    return {
        "username": user, "user": user,
        "domain": domain, "expired": expired, "exp": expired,
        "iplimit": iplimit, "ssh_host": domain,
        "openssh": "22", "dropbear": "109,110,143",
        "ssh_ws_tls": "443", "ssh_ws": "80,8080,8880,2082,2086",
        "payload": f"GET / HTTP/1.1[crlf]Host: {domain}[crlf]Upgrade: websocket[crlf][crlf]",
    }


def create_xray(proto, params):
    user = clean_username(params.get("user") or params.get("username"))
    days = int_param(params, "exp", 1, 1)
    quota = int_param(params, "quota", 0, 0)
    iplimit = int_param(params, "iplimit", 0, 0)

    expired = exp_date(days)
    domain = get_domain()
    uid = str(uuid.uuid4())
    cfg = load_config()

    if proto == "vmess":
        client = {"id": uid, "alterId": 0, "email": user}
        tags = ["vmess-ws", "vmess-grpc"]
        ws_path = "/vmess"; grpc_service = "vmess-grpc"
    elif proto == "vless":
        client = {"id": uid, "email": user}
        tags = ["vless-ws", "vless-grpc"]
        ws_path = "/vless"; grpc_service = "vless-grpc"
    elif proto == "trojan":
        client = {"password": uid, "email": user}
        tags = ["trojan-ws", "trojan-grpc"]
        ws_path = "/trojan-ws"; grpc_service = "trojan-grpc"
    else:
        raise ValueError("Protocol tidak dikenal")

    added = []
    for tag in tags:
        if add_client_to_tag(cfg, tag, dict(client), user):
            added.append(tag)
    if not added:
        raise RuntimeError(f"Inbound tag untuk {proto} tidak ditemukan")

    ensure_metadata(cfg, proto, user, {
        "uuid": uid, "password": uid, "exp": expired,
        "quota": quota, "iplimit": iplimit,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    })
    save_config(cfg)
    save_limit(proto, user, iplimit, quota)
    restart_xray()

    data = {
        "username": user, "user": user, "domain": domain,
        "expired": expired, "exp": expired,
        "uuid": uid, "password": uid,
        "quota": quota, "iplimit": iplimit,
        "ws_path": ws_path, "grpc_service": grpc_service,
        "tls_port": "443", "none_port": "80",
    }

    if proto == "vmess":
        data.update({
            "vmess_tls_link": make_vmess_link(domain, user, uid, 443, True),
            "vmess_nontls_link": make_vmess_link(domain, user, uid, 80, False),
            "link_tls": make_vmess_link(domain, user, uid, 443, True),
            "link_nontls": make_vmess_link(domain, user, uid, 80, False),
        })
    elif proto == "vless":
        tls = (f"vless://{uid}@{domain}:443?security=tls&encryption=none&type=ws"
               f"&host={domain}&path=%2Fvless&sni={domain}#{user}")
        ntls = (f"vless://{uid}@{domain}:80?security=none&encryption=none&type=ws"
                f"&host={domain}&path=%2Fvless#{user}")
        data.update({"vless_tls_link": tls, "vless_nontls_link": ntls,
                     "link_tls": tls, "link_nontls": ntls})
    elif proto == "trojan":
        tls = (f"trojan://{uid}@{domain}:443?security=tls&type=ws"
               f"&host={domain}&path=%2Ftrojan-ws&sni={domain}#{user}")
        ntls = (f"trojan://{uid}@{domain}:80?security=none&type=ws"
                f"&host={domain}&path=%2Ftrojan-ws#{user}")
        data.update({"trojan_tls_link": tls, "trojan_nontls_link": ntls,
                     "link_tls": tls, "link_nontls": ntls})
    return data


GET_OK = {"", "health", "status"}
POST_REQUIRED = {"createssh"}                            # password endpoint
POST_OR_GET = {"createvmess", "createvless", "createtrojan"}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers",
                         "Content-Type, Authorization, X-API-Key")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()

    def do_GET(self):  self.handle_request()
    def do_POST(self): self.handle_request()

    def handle_request(self):
        try:
            path, params, is_post = parse_request(self)

            if path in GET_OK:
                return response(self, 200, {
                    "status": "success",
                    "message": "v7fix BotVPN API active",
                    "host": HOST, "port": PORT,
                })

            if not auth_ok(self.headers):
                return response(self, 401, {
                    "status": "error",
                    "message": "Unauthorized — supply token via X-API-Key or Authorization header",
                })

            if path in POST_REQUIRED and not is_post:
                return response(self, 405, {
                    "status": "error",
                    "message": f"Endpoint /{path} hanya menerima POST (password tidak boleh via GET)",
                })

            if path == "createssh":
                data = create_ssh(params)
            elif path == "createvmess":
                data = create_xray("vmess", params)
            elif path == "createvless":
                data = create_xray("vless", params)
            elif path == "createtrojan":
                data = create_xray("trojan", params)
            else:
                return response(self, 404, {
                    "status": "error",
                    "message": f"Endpoint /{path} tidak ditemukan",
                })

            return response(self, 200, {
                "status": "success",
                "message": "Account created",
                "data": data,
            })

        except ValueError as e:
            return response(self, 400, {"status": "error", "message": str(e)})
        except Exception as e:
            return response(self, 500, {"status": "error", "message": str(e)})


def main():
    os.makedirs("/etc/Anggun", exist_ok=True)
    get_token()
    server = HTTPServer((HOST, PORT), Handler)
    print(f"v7fix BotVPN API running on {HOST}:{PORT}")
    print(f"Xray binary: {XRAY_BIN}")
    server.serve_forever()


if __name__ == "__main__":
    main()
