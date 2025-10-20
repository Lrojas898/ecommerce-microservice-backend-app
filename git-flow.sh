#!/bin/bash

# Git Flow Helper Script
# Facilita el uso de la branching strategy

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${GREEN}Git Flow Helper - Ecommerce Microservices${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Usage:${NC}
  ./git-flow.sh <command> [arguments]

${YELLOW}Commands:${NC}

  ${GREEN}init${NC}
      Inicializa la branching strategy (crea develop)

  ${GREEN}feature start <nombre>${NC}
      Crea un nuevo feature branch desde develop
      Ejemplo: ./git-flow.sh feature start add-reviews

  ${GREEN}feature finish <nombre>${NC}
      Finaliza un feature (merge a develop)
      Ejemplo: ./git-flow.sh feature finish add-reviews

  ${GREEN}release start <version>${NC}
      Crea un release branch desde develop
      Ejemplo: ./git-flow.sh release start 1.2.0

  ${GREEN}release finish <version>${NC}
      Finaliza un release (merge a master con tag)
      Ejemplo: ./git-flow.sh release finish 1.2.0

  ${GREEN}hotfix start <nombre>${NC}
      Crea un hotfix branch desde master
      Ejemplo: ./git-flow.sh hotfix start critical-bug

  ${GREEN}hotfix finish <nombre> <version>${NC}
      Finaliza un hotfix (merge a master y develop)
      Ejemplo: ./git-flow.sh hotfix finish critical-bug 1.2.1

  ${GREEN}status${NC}
      Muestra el estado actual de los branches

  ${GREEN}sync${NC}
      Sincroniza todos los branches principales

${YELLOW}Examples:${NC}

  # Workflow completo de feature
  ./git-flow.sh feature start user-authentication
  # ... desarrollar ...
  git add . && git commit -m "feat: add user authentication"
  ./git-flow.sh feature finish user-authentication

  # Workflow de release
  ./git-flow.sh release start 1.3.0
  # QA valida en staging...
  ./git-flow.sh release finish 1.3.0

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# Verificar que estamos en un repo git
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: No estás en un repositorio Git${NC}"
        exit 1
    fi
}

# Init: Crear branch develop
cmd_init() {
    echo -e "${BLUE}Inicializando branching strategy...${NC}"

    # Verificar si develop ya existe
    if git show-ref --verify --quiet refs/heads/develop; then
        echo -e "${YELLOW}Branch 'develop' ya existe${NC}"
    else
        git checkout -b develop
        git push -u origin develop
        echo -e "${GREEN}✓ Branch 'develop' creado${NC}"
    fi

    echo -e "${GREEN}✓ Inicialización completa${NC}"
    echo -e "${YELLOW}Branches principales:${NC}"
    echo -e "  - ${GREEN}master${NC}  → Production"
    echo -e "  - ${GREEN}develop${NC} → Development"
}

# Feature start
cmd_feature_start() {
    local feature_name=$1

    if [ -z "$feature_name" ]; then
        echo -e "${RED}Error: Debes especificar el nombre del feature${NC}"
        echo -e "Uso: ./git-flow.sh feature start <nombre>"
        exit 1
    fi

    echo -e "${BLUE}Creando feature branch...${NC}"

    # Actualizar develop
    git checkout develop
    git pull origin develop

    # Crear feature branch
    git checkout -b "feature/${feature_name}"

    echo -e "${GREEN}✓ Feature branch creado: feature/${feature_name}${NC}"
    echo -e "${YELLOW}Siguiente paso:${NC}"
    echo -e "  1. Desarrollar tu feature"
    echo -e "  2. git add . && git commit -m 'feat: descripción'"
    echo -e "  3. git push -u origin feature/${feature_name}"
    echo -e "  4. ./git-flow.sh feature finish ${feature_name}"
}

# Feature finish
cmd_feature_finish() {
    local feature_name=$1

    if [ -z "$feature_name" ]; then
        echo -e "${RED}Error: Debes especificar el nombre del feature${NC}"
        exit 1
    fi

    local branch_name="feature/${feature_name}"

    echo -e "${BLUE}Finalizando feature...${NC}"

    # Verificar que estamos en el branch correcto
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "$branch_name" ]; then
        git checkout "$branch_name"
    fi

    # Push final
    git push origin "$branch_name"

    # Merge a develop
    git checkout develop
    git pull origin develop
    git merge --no-ff "$branch_name" -m "Merge feature/${feature_name} into develop"
    git push origin develop

    # Eliminar branch local y remoto
    git branch -d "$branch_name"
    git push origin --delete "$branch_name"

    echo -e "${GREEN}✓ Feature finalizado y mergeado a develop${NC}"
    echo -e "${YELLOW}Pipeline DEV se ejecutará automáticamente${NC}"
}

# Release start
cmd_release_start() {
    local version=$1

    if [ -z "$version" ]; then
        echo -e "${RED}Error: Debes especificar la versión${NC}"
        echo -e "Uso: ./git-flow.sh release start <version>"
        echo -e "Ejemplo: ./git-flow.sh release start 1.2.0"
        exit 1
    fi

    echo -e "${BLUE}Creando release branch...${NC}"

    # Actualizar develop
    git checkout develop
    git pull origin develop

    # Crear release branch
    git checkout -b "release/v${version}"
    git push -u origin "release/v${version}"

    echo -e "${GREEN}✓ Release branch creado: release/v${version}${NC}"
    echo -e "${YELLOW}Pipeline STAGE se ejecutará automáticamente${NC}"
    echo -e "${YELLOW}Siguiente paso:${NC}"
    echo -e "  1. Esperar que el pipeline complete"
    echo -e "  2. QA valida en staging namespace"
    echo -e "  3. Si aprueba: ./git-flow.sh release finish ${version}"
}

# Release finish
cmd_release_finish() {
    local version=$1

    if [ -z "$version" ]; then
        echo -e "${RED}Error: Debes especificar la versión${NC}"
        exit 1
    fi

    local branch_name="release/v${version}"

    echo -e "${BLUE}Finalizando release...${NC}"

    # Merge a master
    git checkout master
    git pull origin master
    git merge --no-ff "$branch_name" -m "Release v${version}"

    # Crear tag
    git tag -a "v${version}" -m "Version ${version}"

    # Push a master con tags
    git push origin master --tags

    echo -e "${GREEN}✓ Release mergeado a master con tag v${version}${NC}"
    echo -e "${YELLOW}Pipeline PROD se ejecutará (requiere aprobación manual)${NC}"

    # Sincronizar develop
    git checkout develop
    git merge master
    git push origin develop

    # Eliminar release branch
    git branch -d "$branch_name"
    git push origin --delete "$branch_name"

    echo -e "${GREEN}✓ Release completado y develop sincronizado${NC}"
}

# Hotfix start
cmd_hotfix_start() {
    local hotfix_name=$1

    if [ -z "$hotfix_name" ]; then
        echo -e "${RED}Error: Debes especificar el nombre del hotfix${NC}"
        exit 1
    fi

    echo -e "${BLUE}Creando hotfix branch...${NC}"

    # Crear desde master
    git checkout master
    git pull origin master
    git checkout -b "hotfix/${hotfix_name}"

    echo -e "${GREEN}✓ Hotfix branch creado: hotfix/${hotfix_name}${NC}"
    echo -e "${RED}⚠️  HOTFIX - Solo para emergencias de producción${NC}"
}

# Hotfix finish
cmd_hotfix_finish() {
    local hotfix_name=$1
    local version=$2

    if [ -z "$hotfix_name" ] || [ -z "$version" ]; then
        echo -e "${RED}Error: Debes especificar nombre y versión${NC}"
        echo -e "Uso: ./git-flow.sh hotfix finish <nombre> <version>"
        exit 1
    fi

    local branch_name="hotfix/${hotfix_name}"

    echo -e "${BLUE}Finalizando hotfix...${NC}"

    # Push hotfix branch
    git push origin "$branch_name"

    # Merge a master
    git checkout master
    git pull origin master
    git merge --no-ff "$branch_name" -m "Hotfix: ${hotfix_name}"
    git tag -a "v${version}" -m "Hotfix ${version}: ${hotfix_name}"
    git push origin master --tags

    # Merge a develop
    git checkout develop
    git pull origin develop
    git merge --no-ff "$branch_name" -m "Hotfix: ${hotfix_name}"
    git push origin develop

    # Eliminar hotfix branch
    git branch -d "$branch_name"
    git push origin --delete "$branch_name"

    echo -e "${GREEN}✓ Hotfix aplicado a master y develop${NC}"
}

# Status
cmd_status() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Estado de Branches${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    echo -e "\n${YELLOW}Branch actual:${NC}"
    git branch --show-current

    echo -e "\n${YELLOW}Branches locales:${NC}"
    git branch

    echo -e "\n${YELLOW}Branches remotos:${NC}"
    git branch -r

    echo -e "\n${YELLOW}Últimos tags:${NC}"
    git tag --sort=-v:refname | head -5

    echo -e "\n${YELLOW}Último commit en cada branch principal:${NC}"
    for branch in master develop; do
        if git show-ref --verify --quiet refs/heads/$branch; then
            echo -e "${GREEN}${branch}:${NC}"
            git log $branch --oneline -1
        fi
    done
}

# Sync
cmd_sync() {
    echo -e "${BLUE}Sincronizando branches principales...${NC}"

    git fetch --all --prune

    for branch in master develop; do
        if git show-ref --verify --quiet refs/heads/$branch; then
            echo -e "${YELLOW}Actualizando ${branch}...${NC}"
            git checkout $branch
            git pull origin $branch
        fi
    done

    echo -e "${GREEN}✓ Sincronización completa${NC}"
}

# Main
check_git_repo

case "$1" in
    init)
        cmd_init
        ;;
    feature)
        case "$2" in
            start)
                cmd_feature_start "$3"
                ;;
            finish)
                cmd_feature_finish "$3"
                ;;
            *)
                echo -e "${RED}Error: Subcomando inválido${NC}"
                echo -e "Uso: ./git-flow.sh feature [start|finish] <nombre>"
                exit 1
                ;;
        esac
        ;;
    release)
        case "$2" in
            start)
                cmd_release_start "$3"
                ;;
            finish)
                cmd_release_finish "$3"
                ;;
            *)
                echo -e "${RED}Error: Subcomando inválido${NC}"
                exit 1
                ;;
        esac
        ;;
    hotfix)
        case "$2" in
            start)
                cmd_hotfix_start "$3"
                ;;
            finish)
                cmd_hotfix_finish "$3" "$4"
                ;;
            *)
                echo -e "${RED}Error: Subcomando inválido${NC}"
                exit 1
                ;;
        esac
        ;;
    status)
        cmd_status
        ;;
    sync)
        cmd_sync
        ;;
    help|--help|-h)
        print_help
        ;;
    *)
        echo -e "${RED}Error: Comando inválido${NC}"
        print_help
        exit 1
        ;;
esac
