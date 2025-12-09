#!/bin/bash
# docker-build.sh - Build Docker image customizada
# Uso: ./scripts/docker-build.sh [tag-opcional]

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🐳 Build Docker - Chatwoot Enterprise Custom${NC}"
echo "================================================"

# Verificar se está na branch main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}⚠️  Você não está na branch main${NC}"
    echo -e "${YELLOW}   Branch atual: ${RED}$CURRENT_BRANCH${NC}"
    read -p "   Deseja continuar mesmo assim? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Build cancelado${NC}"
        exit 1
    fi
fi

# Obter versão do package.json
VERSION=$(cat package.json | grep '"version"' | head -1 | awk -F'"' '{print $4}')
DATE=$(date +%Y%m%d)

# Tag customizada ou usar padrão
if [ -z "$1" ]; then
    CUSTOM_TAG="v${VERSION}-custom-${DATE}"
else
    CUSTOM_TAG="$1"
fi

# ALTERE AQUI: Seu username do Docker Hub
DOCKER_USERNAME="hamielh"
IMAGE_NAME="${DOCKER_USERNAME}/chatwooth"

echo -e "\n${BLUE}📋 Informações do Build:${NC}"
echo -e "   Versão Chatwoot: ${GREEN}$VERSION${NC}"
echo -e "   Tag customizada: ${GREEN}$CUSTOM_TAG${NC}"
echo -e "   Imagem completa: ${GREEN}$IMAGE_NAME:$CUSTOM_TAG${NC}"
echo -e "   Branch: ${GREEN}$CURRENT_BRANCH${NC}"

# Confirmar build
echo -e "\n${YELLOW}⚠️  Isso vai buildar a imagem Docker${NC}"
read -p "   Deseja continuar? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Build cancelado${NC}"
    exit 1
fi

# Build da imagem
echo -e "\n${YELLOW}🔨 Buildando imagem Docker...${NC}"
echo -e "${YELLOW}   (Isso pode demorar 10-20 minutos)${NC}\n"

docker build \
  -f docker/Dockerfile \
  -t "$IMAGE_NAME:$CUSTOM_TAG" \
  -t "$IMAGE_NAME:latest" \
  --build-arg RAILS_ENV=production \
  .

# Verificar se build foi bem sucedido
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Build concluído com sucesso!${NC}"
    echo "================================================"
    echo -e "${BLUE}📦 Imagens criadas:${NC}"
    echo -e "   ${GREEN}$IMAGE_NAME:$CUSTOM_TAG${NC}"
    echo -e "   ${GREEN}$IMAGE_NAME:latest${NC}"
    echo ""
    echo -e "${YELLOW}📋 Próximos passos:${NC}"
    echo "  1. Testar a imagem localmente:"
    echo "     docker run --rm -it $IMAGE_NAME:$CUSTOM_TAG rails --version"
    echo ""
    echo "  2. Push para Docker Hub:"
    echo "     ./scripts/docker-push.sh $CUSTOM_TAG"
    echo ""
else
    echo -e "\n${RED}❌ Erro no build!${NC}"
    exit 1
fi
