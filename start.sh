#!/bin/bash

# --- Colores para la terminal ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Iniciando script de despliegue para Traefik-One...${NC}"

# 1. Verificar si Docker está corriendo
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker no está en ejecución. Por favor inicia Docker antes de continuar.${NC}"
    exit 1
fi

# 2. Crear la red compartida 'traefik-public' si no existe
NETWORK_NAME="traefik-public"
if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}🌐 La red Docker '$NETWORK_NAME' no existe. Creándola...${NC}"
    docker network create "$NETWORK_NAME"
    echo -e "${GREEN}✅ Red '$NETWORK_NAME' creada correctamente.${NC}"
else
    echo -e "${GREEN}✅ La red '$NETWORK_NAME' ya existe.${NC}"
fi

# 3. Verificar si el archivo .env existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️ Advertencia: No se encontró el archivo .env.${NC}"
    echo -e "Creando una plantilla básica de .env... ¡Por favor edítalo con tus valores reales!"
    
    cat <<EOF > .env
DOMAIN=idmji.org
EMAILS_FROM_EMAIL=tu-email@gmail.com
USERNAME=admin
# Contraseña cifrada en docker-compose (se requiere escapar con doble $$ en docker)
HASHED_PASSWORD=YOUR_HASHED_PASSWORD_HERE
EOF
    echo -e "${GREEN}📝 Archivo .env básico creado. Recuerda configurar el dominio y tu correo Let's Encrypt.${NC}"
fi

# 4. Levantar Traefik
echo -e "${GREEN}⚡ Levantando el contenedor de Traefik...${NC}"
docker compose -f compose.traefik.yml up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡Traefik se ha iniciado correctamente!${NC}"
    echo -e "Puedes monitorear los logs con: ${YELLOW}docker compose -f compose.traefik.yml logs -f${NC}"
else
    echo -e "${RED}❌ Hubo un error al iniciar Traefik. Revisa los logs anteriores.${NC}"
    exit 1
fi
