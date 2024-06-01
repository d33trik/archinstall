#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

export GUM_SPIN_SHOW_ERROR=true
export GUM_SPIN_SPINNER=line
export GUM_SPIN_SPINNER_FOREGROUND=10
export GUM_SPIN_TITLE_FOREGROUND=15

main() {
    local packages_to_install
    local user_username

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --packages-to-install)
                packages_to_install="$2"
                shift 2
                ;;
            --user-username)
                user_username="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

main "$@"
