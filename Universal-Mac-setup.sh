#!/usr/bin/env bash
# universal-mac-dev-setup.sh
# One-stop interactive dev-env installer for a clean macOS machine.
set -euo pipefail

###############################################################################
# ↓ EDIT THESE ARRAYS IF YOU WANT DIFFERENT TOOLS INSTALLED
###############################################################################
ACADEMIC_BREW_PKGS=(
  python                 # latest CPython
  gcc                    # GNU C/C++ (clang already in Xcode CLI)
  openjdk                # Java 21 LTS
)
ACADEMIC_CASKS=(
  visual-studio-code
)

DATASCIENCE_CASKS=(
  miniconda
)
DATASCIENCE_CONDA_ENV=datasci
DATASCIENCE_PY_PKGS=("numpy" "pandas" "matplotlib" "scipy" "scikit-learn" "jupyterlab")

WEBDEV_PY_PKGS=("virtualenv" "pipenv" "poetry" "django" "flask" "fastapi" "uvicorn[standard]" "pytest")
WEBDEV_JS_GLOBALS=("yarn" "pnpm" "create-react-app" "vite")

###############################################################################
print_header() {
  printf "\n\033[1m=== %s ===\033[0m\n" "$1"
}

require_power() {
  print_header "Power Check"
  read -rp "Is your Mac plugged in to AC power? (y/n) " ans
  ans_lc=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
  [[ "$ans_lc" == "y" ]] || { echo "→ Plug in first, then re-run."; exit 1; }
}


install_xcode_cli() {
  print_header "Xcode Command Line Tools"
  if ! xcode-select -p &>/dev/null; then
    echo "→ Installing Xcode CLI tools…"; xcode-select --install
    echo "  (Accept the popup, then re-run this script when it finishes.)"
    read -rp "Press Enter after installation is complete. "
  else
    echo "✔ Xcode CLI tools already installed."
  fi
}



install_homebrew() {
  print_header "Homebrew"
  if ! command -v brew &>/dev/null; then
    echo "→ Installing Homebrew…"
    /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "✔ Homebrew already installed."
    brew update
  fi
}

brew_install() {
  local pkgs=("$@")
  (( ${#pkgs[@]} )) || return
  brew install "${pkgs[@]}"
}

brew_install_casks() {
  local casks=("$@")
  (( ${#casks[@]} )) || return
  brew install --cask "${casks[@]}"
}

setup_academic() {
  print_header "Academic / General-Learning Stack"
  brew_install "${ACADEMIC_BREW_PKGS[@]}"
  brew_install_casks "${ACADEMIC_CASKS[@]}"
  echo "→ Setting VS Code shell integration."
  code --install-extension ms-python.python ms-vscode.cpptools redhat.java &>/dev/null || true
}

setup_datascience() {
  print_header "Data-Science Stack"
  brew_install_casks "${DATASCIENCE_CASKS[@]}"
  source ~/miniconda3/etc/profile.d/conda.sh
  if ! conda env list | grep -q "$DATASCIENCE_CONDA_ENV"; then
    conda create -y -n "$DATASCIENCE_CONDA_ENV" python=3.12 "${DATASCIENCE_PY_PKGS[@]}"
  fi
  echo "✔ Conda env '$DATASCIENCE_CONDA_ENV' ready.  Activate with:  conda activate $DATASCIENCE_CONDA_ENV"
}

setup_web_python() {
  print_header "Web-Dev (Python) Stack"
  brew_install pyenv
  if ! grep -q "pyenv init" ~/.zprofile; then
    echo 'eval "$(pyenv init --path)"' >> ~/.zprofile
    echo 'eval "$(pyenv init -)"'       >> ~/.zprofile
  fi
  PYVER="$(pyenv install --list | grep -E ' 3\.12\.[0-9]+$' | tail -1 | tr -d ' ')"
  pyenv install -s "$PYVER"
  pyenv global  "$PYVER"
  pip3 install --upgrade pip
  pip3 install "${WEBDEV_PY_PKGS[@]}"
}

setup_web_js() {
  print_header "Web-Dev (JavaScript) Stack"
  brew_install nvm
  [[ -d ~/.nvm ]] || mkdir ~/.nvm
  grep -q "NVM_DIR" ~/.zprofile || {
    cat >> ~/.zprofile <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix nvm)/nvm.sh" ] && . "$(brew --prefix nvm)/nvm.sh"
EOF
  }
  # shellcheck source=/dev/null
  source ~/.zprofile
  nvm install --lts
  npm install -g "${WEBDEV_JS_GLOBALS[@]}"
}

main_menu() {
  print_header "Environment Selection"
  echo "Choose one setup option:"
  echo "  1) Academic / General-Learning"
  echo "  2) Data-Science"
  echo "  3) Web-Dev"
  read -rp "Enter 1-3: " choice
  case "$choice" in
    1) setup_academic ;;
    2) setup_datascience ;;
    3)
       echo
       echo " Web-Dev stack:"
       echo "  a) Python (Django / FastAPI etc.)"
       echo "  b) JavaScript (Node / React / Vite etc.)"
       read -rp "Enter a/b: " sub
       case "${sub,,}" in
         a) setup_web_python ;;
         b) setup_web_js ;;
         *) echo "Invalid"; exit 1 ;;
       esac
       ;;
    *) echo "Invalid"; exit 1 ;;
  esac
}

###############################################################################
# RUN
###############################################################################
require_power
install_xcode_cli
install_homebrew
main_menu
print_header "Done ✔"
echo "Open a new terminal session (or 'source ~/.zprofile') for PATH changes to take effect."