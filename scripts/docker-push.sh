#!/bin/bash
# docker-push.sh - Push imagem para Docker Hub
# Uso: ./scripts/docker-push.sh [tag-opcional]

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Push Docker Hub - Chatwoot Enterprise Custom${NC}"
echo "================================================"

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

echo -e "\n${BLUE}📋 Informações do Push:${NC}"
echo -e "   Imagem: ${GREEN}$IMAGE_NAME${NC}"
echo -e "   Tags: ${GREEN}$CUSTOM_TAG, latest${NC}"

# Verificar se imagem existe localmente
if ! docker images | grep -q "$IMAGE_NAME"; then
    echo -e "\n${RED}❌ Imagem $IMAGE_NAME não encontrada!${NC}"
    echo -e "${YELLOW}   Execute primeiro:${NC}"
    echo "   ./scripts/docker-build.sh"
    exit 1
fi

# Verificar login no Docker Hub
echo -e "\n${YELLOW}🔑 Verificando login no Docker Hub...${NC}"
if ! docker info | grep -q "Username: $DOCKER_USERNAME"; then
    echo -e "${YELLOW}   Você precisa fazer login no Docker Hub${NC}"
    docker login
fi

# Confirmar push
echo -e "\n${YELLOW}⚠️  Isso vai fazer push para Docker Hub (público)${NC}"
read -p "   Deseja continuar? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Push cancelado${NC}"
    exit 1
fi

# Push das imagens
echo -e "\n${YELLOW}📤 Fazendo push da tag: $CUSTOM_TAG${NC}"
docker push "$IMAGE_NAME:$CUSTOM_TAG"

echo -e "\n${YELLOW}📤 Fazendo push da tag: latest${NC}"
docker push "$IMAGE_NAME:latest"

# Sucesso
echo -e "\n${GREEN}✅ Push concluído com sucesso!${NC}"
echo "================================================"
echo -e "${BLUE}🌐 Imagens disponíveis:${NC}"
echo -e "   https://hub.docker.com/r/$DOCKER_USERNAME/chatwoot-enterprise"
echo ""
echo -e "${YELLOW}📋 Para usar em produção:${NC}"
echo "  docker pull $IMAGE_NAME:$CUSTOM_TAG"
echo "  docker-compose -f docker-compose.production.yaml up -d"
echo ""
