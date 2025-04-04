#!/bin/bash

rename-folder old_name new_name:
#!/usr/bin/env bash
set -euo pipefail

if [ -d "{{old_name}}" ]; then
  mv "{{old_name}}" "{{new_name}}"
  echo "Renamed '{{old_name}}' to '{{new_name}}'"
else
  echo "Error: Folder '{{old_name}}' not found."
  exit 1
fi
