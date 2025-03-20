#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

main() {
	synchronize_package_databases
}

synchronize_package_databases() {
	pacman -Sy
}

main "$@"
