#!/bin/bash
# update-fork.sh - Atualizar fork com upstream
# Uso: ./scripts/update-fork.sh

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔄 Atualizando fork com upstream Chatwoot...${NC}"
echo "================================"

# Salvar branch atual
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${YELLOW}📍 Branch atual: ${GREEN}$CURRENT_BRANCH${NC}"

# 1. Fetch tudo
echo -e "\n${YELLOW}📡 Buscando atualizações do upstream...${NC}"
git fetch upstream --quiet
git fetch origin --quiet
echo -e "${GREEN}✅ Fetch concluído${NC}"

# 2. Atualizar develop
echo -e "\n${YELLOW}🔄 Sincronizando develop com upstream/develop...${NC}"
git checkout develop
BEFORE_VERSION=$(cat package.json | grep '"version"' | head -1)
git reset --hard upstream/develop
AFTER_VERSION=$(cat package.json | grep '"version"' | head -1)
echo -e "${GREEN}✅ develop atualizado${NC}"
echo -e "   Versão: $AFTER_VERSION"

# 3. Atualizar staging com rebase
echo -e "\n${YELLOW}🔧 Atualizando staging (suas mods)...${NC}"
git checkout staging

echo -e "${YELLOW}   Fazendo rebase com develop...${NC}"
if git rebase develop; then
    echo -e "${GREEN}✅ Rebase concluído sem conflitos${NC}"
else
    echo -e "${RED}❌ Conflitos detectados!${NC}"
    echo -e "${YELLOW}Resolva os conflitos manualmente:${NC}"
    echo "  1. Edite os arquivos em conflito"
    echo "  2. git add <arquivos-resolvidos>"
    echo "  3. git rebase --continue"
    echo ""
    echo -e "${YELLOW}Ou aborte o rebase:${NC}"
    echo "  git rebase --abort"
    exit 1
fi

# 4. Instalar dependências
echo -e "\n${YELLOW}📦 Instalando dependências...${NC}"
bundle install --quiet
pnpm install --silent
echo -e "${GREEN}✅ Dependências instaladas${NC}"

# 5. Rodar migrações
echo -e "\n${YELLOW}🗄️  Rodando migrações do banco...${NC}"
bundle exec rails db:migrate
echo -e "${GREEN}✅ Migrações concluídas${NC}"

# 6. Resumo
echo ""
echo -e "${GREEN}🎉 Atualização concluída com sucesso!${NC}"
echo "================================"
echo -e "${BLUE}📊 Resumo:${NC}"
echo -e "   develop → ${GREEN}Sincronizado com upstream${NC}"
echo -e "   staging → ${GREEN}Pronto para testes${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo "  1. Testar em staging:"
echo "     ./start_chatwoot.sh"
echo ""
echo "  2. Se tudo OK, mergear pra main:"
echo "     ./scripts/deploy-to-production.sh"
echo ""
echo "  3. Push das mudanças:"
echo "     git push origin develop --force"
echo "     git push origin staging --force"
echo "     git push origin main"
echo ""

# Voltar pra branch original
git checkout $CURRENT_BRANCH
echo -e "${GREEN}✅ Voltou para branch: $CURRENT_BRANCH${NC}"
