#!/usr/bin/env bash
set -euo pipefail
exec mkdocs build --strict --site-dir site
