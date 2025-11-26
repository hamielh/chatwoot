#!/bin/bash
# deploy-to-production.sh - Deploy staging para produção (main)
# Uso: ./scripts/deploy-to-production.sh

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploy para Produção (main)${NC}"
echo "================================"

# Verificar se está em staging
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "staging" ]; then
    echo -e "${YELLOW}⚠️  Você não está na branch staging${NC}"
    echo -e "${YELLOW}   Trocando para staging...${NC}"
    git checkout staging
fi

# Verificar se há mudanças não commitadas
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}❌ Existem mudanças não commitadas!${NC}"
    echo -e "${YELLOW}   Commit ou stash suas mudanças antes de continuar.${NC}"
    git status -s
    exit 1
fi

# Rodar testes (opcional - descomente se tiver testes)
# echo -e "\n${YELLOW}🧪 Rodando testes...${NC}"
# bundle exec rspec
# pnpm test

# Confirmar deploy
echo -e "\n${YELLOW}⚠️  Você está prestes a fazer deploy para PRODUÇÃO (main)${NC}"
echo -e "${YELLOW}   Branch atual: ${GREEN}staging${NC}"
read -p "   Deseja continuar? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deploy cancelado${NC}"
    exit 1
fi

# Mergear staging em main
echo -e "\n${YELLOW}🔀 Mergeando staging → main...${NC}"
git checkout main
git merge staging --no-ff -m "chore: Deploy staging to production"
echo -e "${GREEN}✅ Merge concluído${NC}"

# Criar tag de versão
VERSION=$(cat package.json | grep '"version"' | head -1 | awk -F'"' '{print $4}')
TAG="v${VERSION}-custom-$(date +%Y%m%d)"
echo -e "\n${YELLOW}🏷️  Criando tag: ${GREEN}$TAG${NC}"
git tag -a $TAG -m "Production release $TAG"

# Mostrar resumo
echo ""
echo -e "${GREEN}🎉 Deploy para produção concluído!${NC}"
echo "================================"
echo -e "${BLUE}📊 Resumo:${NC}"
echo -e "   Branch: ${GREEN}main${NC}"
echo -e "   Tag: ${GREEN}$TAG${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo "  1. Push para repositório:"
echo "     git push origin main"
echo "     git push origin $TAG"
echo ""
echo "  2. Voltar para staging:"
echo "     git checkout staging"
echo ""
