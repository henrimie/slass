#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "You are not root. Aborting."
  exit 1
else
