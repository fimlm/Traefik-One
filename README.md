# Traefik-One 🚀

**Traefik-One** es el sustituto moderno, seguro y automatizado de Nginx para este servidor. Utiliza **Traefik v3.7** para enrutar el tráfico de múltiples dominios hacia contenedores Docker y servicios locales de forma transparente y con emisión/renovación automática de certificados SSL (Let's Encrypt).

---

## Características 🛡️

- **Certificados SSL Automáticos**: Emisión mediante el reto **HTTP-01** en el puerto 80 sin intervención manual ni dependencias de Certbot.
- **Configuración en Caliente**: Proveedor dinámico por archivos en la carpeta `dynamic/` que permite añadir y modificar dominios sin reiniciar el proxy principal.
- **Robustez y Hardening**:
  - Cabeceras de seguridad globales (`X-Frame-Options`, `Content-Security-Policy`, etc.).
  - Limitación de tráfico integrada (Rate Limiting general y API) para mitigar denegación de servicio.
- **Soporte de WebSockets Nativo**: Listo para Next.js, FastAPI y herramientas de mensajería (como Chatwoot/n8n) sin configuraciones engorrosas.

---

## Requisitos Previos 📋

1. **Docker y Docker Compose** instalados en el servidor.
2. Los puertos **80** y **443** deben estar libres (asegúrate de apagar Nginx local: `sudo systemctl stop nginx`).

---

## Estructura del Repositorio 📂

```text
Traefik-One/
├── compose.traefik.yml      # Configuración base de Traefik y middlewares de seguridad
├── start.sh                 # Script automatizado de inicio y verificación de red
├── .env                     # Variables de entorno (Dominio principal, Email de Let's Encrypt)
└── dynamic/
    └── dynamic_conf.yml     # Archivo dinámico para registrar las rutas y puertos de tus apps
```

---

## Despliegue Rápido ⚡

1. Dale permisos de ejecución al script `start.sh`:
   ```bash
   chmod +x start.sh
   ```

2. Ejecuta el script de inicio:
   ```bash
   ./start.sh
   ```
   *El script se encargará de crear la red compartida `traefik-public` si no existe, generar una plantilla de `.env` si hace falta y levantar el contenedor de Traefik.*

3. Modifica tu `.env` recién creado para asignar tu dominio y correo:
   ```env
   DOMAIN=idmji.org
   EMAILS_FROM_EMAIL=tu-email@gmail.com
   USERNAME=admin
   HASHED_PASSWORD=YOUR_HASHED_PASSWORD_HERE 
   # Generado con htpasswd o comando echo
   ```

---

## Cómo Migrar Nuevos Sitios (Ejemplo: informes) 📝

Para migrar una aplicación, simplemente edita [dynamic/dynamic_conf.yml](file:///Users/angelosorno/Documents/VSCode/Projects/NGINX-One/Traefik-One/dynamic/dynamic_conf.yml) y añade su enrutador y servicio.

**Ejemplo de informes.idmji.org**:
```yaml
http:
  routers:
    informes:
      rule: Host(`informes.idmji.org`)
      entryPoints:
        - https
      service: informes-service
      tls:
        certResolver: le
      middlewares:
        - security-headers  # Inyecta cabeceras de seguridad
        - limit-general     # Inyecta rate limit general

  services:
    informes-service:
      loadBalancer:
        servers:
          - url: http://host.docker.internal:3000  # Redirige al puerto host expuesto
```

Al guardar el archivo, **Traefik leerá los cambios inmediatamente sin necesidad de reiniciarse**, solicitará el certificado a Let's Encrypt y activará el sitio en producción.

---

## Dashboard de Traefik 🔐

El acceso público y la generación SSL para el dashboard de administración visual de Traefik (`traefik.tu-dominio.com`) han sido **desactivados por defecto**.

Si en algún momento requieres activar el Dashboard para visualizar las rutas y el estado en tiempo real, realiza los siguientes pasos:
1. Abre el archivo [compose.traefik.yml].
2. Modifica la etiqueta `traefik.enable` cambiándola de `false` a `true`:
   ```yaml
   labels:
     - traefik.enable=true
   ```
3. Descomenta las líneas del enrutador y el middleware de autenticación (`basicauth`) que están comentadas en la sección de `labels`.
4. Aplica los cambios forzando la recreación del contenedor en el servidor:
   ```bash
   docker compose -f compose.traefik.yml up -d --force-recreate
   ```

---

> [!TIP]
> 🔄 **Actualización en Caliente (Hot Reload)**: Como Traefik tiene habilitada la directiva `watch: true` en el File Provider, **no necesitas reiniciar el contenedor de Traefik** para dar de alta nuevos dominios. En cuanto hagas `git pull` en el servidor con los nuevos cambios en `dynamic_conf.yml`, Traefik los detectará de inmediato en caliente, creará el reto SSL y activará tu sitio seguro en segundos sin afectar al resto de las aplicaciones activas.

