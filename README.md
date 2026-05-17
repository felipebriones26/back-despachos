# Innovatech Chile - Sistema Distribuido de Gestión de Ventas y Despachos (EP2)

Este repositorio contiene la solución contenerizada y automatizada para la operación logística de Innovatech Chile, estructurada mediante una arquitectura de microservicios eficiente, escalable y segura desplegada en Amazon Web Services (AWS).

[cite_start]De acuerdo con los requerimientos institucionales, este archivo detalla el funcionamiento completo del sistema, sus decisiones de diseño de infraestructura y el proceso de despliegue.

---

## 1. Componentes del Sistema Distribuido

La arquitectura del ecosistema se compone de tres proyectos independientes que colaboran de manera distribuida:

1. Frontend (`front_despacho`): Interfaz de usuario interactiva desarrollada en React (Vite) y estilizada con Tailwind CSS. Expone el puerto público `80`.
2. Backend Ventas (`back-ventas_springboot`): API REST construida en Spring Boot encargada de la gestión de órdenes de compra y facturación. Opera en el puerto `8082`.
3. Backend Despachos (`back-Despachos_SpringBoot`): API REST en Spring Boot responsable de la asignación de camiones, control de intentos y cierre logístico de despachos. Opera en el puerto `8081`.

---

## 2. Diseño de la Contenedorización (Docker)

[cite_start]Cada uno de los componentes incluye la configuración necesaria para ejecutarse de forma independiente y conjunta en entornos contenerizados[cite: 161]:

* Multi-stage Build: Se utiliza compilación en múltiples etapas en los Dockerfiles. Separa el entorno de construcción pesado (Build SDK / Maven / Node) del artefacto final de ejecución en producción (Runtime liviano). [cite_start]Esto minimiza el tamaño de las imágenes finales y reduce la superficie de riesgo[cite: 158, 220].
* Usuario No-Root (Menor Privilegio): Los procesos internos de los contenedores no se ejecutan como root, sino bajo un perfil de usuario limitado configurado explícitamente, evitando escaladas de privilegios no autorizadas hacia la instancia host de AWS EC2[cite: 220].
* [cite_start]Optimización de Capas: Las instrucciones del Dockerfile están ordenadas estratégicamente para aprovechar la caché de Docker, instalando primero las dependencias estáticas y agilizando las compilaciones automáticas[cite: 220].

---

## 3. Orquestación y Redes con Docker Compose

[cite_start]La suite completa de servicios se orquesta centralizadamente mediante un archivo `docker-compose.yml` que define variables de entorno, puertos, dependencias y redes virtuales[cite: 160, 221]:

```yaml
version: '3.8'

services:
  front-despacho:
    image: felipebriones26/front-despacho:latest
    ports:
      - "80:80"
    networks:
      - red-innovatech

  back-ventas:
    image: felipebriones26/back-ventas:latest
    ports:
      - "8082:8082"
    networks:
      - red-innovatech

  back-despachos:
    image: felipebriones26/back-despachos:latest
    ports:
      - "8081:8081"
    networks:
      - red-innovatech

networks:
  red-innovatech:
    driver: bridge

Integración y Seguridad (CORS)La comunicación efectiva entre el Frontend y los Backends respeta estrictamente las políticas de seguridad de AWS. Se habilitó la directiva @CrossOrigin(origins = "*") en los controladores Java de Spring Boot y se configuraron reglas de entrada (Inbound Rules) en los Security Groups de AWS para permitir tráfico TCP en los puertos 8081 y 8082, garantizando que las peticiones asíncronas de Axios se procesen sin bloqueos. 
4. Estrategia de Persistencia de DatosPara asegurar la continuidad operativa de la empresa ante reinicios de contenedores o actualizaciones del sistema, se implementó persistencia de datos acoplada a AWS RDS (MySQL):  Estrategia Identity: Las entidades de Java utilizan GenerationType.IDENTITY para delegar la autogeneración de llaves primarias de manera nativa al atributo AUTO_INCREMENT de las tablas en MySQL, evitando colisiones de secuencias globales en entornos distribuidos.
Mapeo Físico Desacoplado: Se incorporó la anotación @Column(name = "despachado") sobre la propiedad lógica de negocio entregado en la entidad Despacho.java, permitiendo sintonizar el lenguaje del Frontend con React sin alterar o romper el esquema de datos físico preexistente en el servidor.
5. Pipeline de Integración y Despliegue Continuo (CI/CD)Cada repositorio se automatiza mediante GitHub Actions, ejecutando el flujo completo de construcción y entrega hacia la nube de AWS:  [Push a rama deploy] ➔ [Build de Imagen Docker] ➔ [Push a Docker Hub] ➔ [Despliegue SSH a AWS EC2]
Disparador Automático: El pipeline reacciona de manera exclusiva ante cambios consolidados en la rama deploy.  
Gestión de Credenciales (GitHub Secrets): Se resguardan de forma segura y encriptada las variables críticas, tokens del registro de imágenes y las llaves privadas .pem de AWS.  
Despliegue Continuo (CD): El workflow se conecta de manera automatizada a la instancia EC2 pública por medio de SSH, detiene el stack antiguo, descarga las últimas imágenes del registro y relanza el Docker Compose actualizado en producción en menos de dos minutos.  
6. Instrucciones de Uso y Ejecución LocalRequisitos PreviosDocker Engine y Docker Compose instalados.Git instalado localmente.Pasos para Levantar el ProyectoClonar este repositorio en tu máquina local:Bashgit clone <url-de-tu-repositorio>
Navegar a la carpeta raíz que contiene el archivo docker-compose.yml.Ejecutar el comando de construcción y arranque en segundo plano:Bashdocker-compose up -d --build
Verificar que todos los servicios e infraestructura se encuentren en estado saludable (Up):Bashdocker ps
Acceder al Dashboard abriendo un navegador web e ingresando a http://localhost.
