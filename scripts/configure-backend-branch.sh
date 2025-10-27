#!/bin/bash

# Default branch value
BRANCH="main"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-b|--branch <branch_name>]"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            echo "Usage: $0 [-b|--branch <branch_name>]"
            exit 1
            ;;
    esac
done

# Execute the npx command with the specified branch
npx ampx generate outputs --app-id dh6cojf0ju9er --branch "$BRANCH" --format dart --out-dir lib