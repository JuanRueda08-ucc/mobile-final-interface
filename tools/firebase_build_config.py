"""Convierte el registro Android de Firebase en definiciones para Flutter."""

import argparse
import json
from pathlib import Path

PACKAGE = "com.juanrueda.vigia"


def build_config(source):
    project = source["project_info"]
    matches = [
        client
        for client in source["client"]
        if client["client_info"].get("android_client_info", {}).get("package_name")
        == PACKAGE
    ]
    if len(matches) != 1:
        raise ValueError(f"Se esperaba un registro Android para {PACKAGE}.")
    client = matches[0]
    config = {
        "VIGIA_FIREBASE": "true",
        "VIGIA_FIREBASE_API_KEY": client["api_key"][0]["current_key"],
        "VIGIA_FIREBASE_APP_ID": client["client_info"]["mobilesdk_app_id"],
        "VIGIA_FIREBASE_SENDER_ID": project["project_number"],
        "VIGIA_FIREBASE_PROJECT_ID": project["project_id"],
    }
    if any(not isinstance(value, str) or not value.strip() for value in config.values()):
        raise ValueError("La configuración de Firebase está incompleta.")
    return config


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="google-services.json de Vigía")
    parser.add_argument(
        "--out", type=Path, default=Path(".dart_tool/vigia-firebase.json")
    )
    args = parser.parse_args()
    try:
        data = json.loads(args.input.read_text(encoding="utf-8-sig"))
        config = build_config(data)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        parser.exit(1, f"No se pudo preparar la configuración: {error}\n")
    print(f"Configuración de compilación generada en {args.out}")


if __name__ == "__main__":
    main()
