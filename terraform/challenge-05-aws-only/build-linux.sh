#!/bin/bash
# Script para compilar el binario para Linux usando Docker

echo "🔨 Compilando MediCloudX Exporter para Linux..."

# Construir imagen Docker
docker build -t medicloudx-builder .

# Crear contenedor y copiar el binario compilado
docker create --name temp-container medicloudx-builder
docker cp temp-container:/build/medicloudx_exporter ./medicloudx_exporter_linux
docker rm temp-container

# Verificar el binario
echo ""
echo "✅ Binario Linux generado:"
file ./medicloudx_exporter_linux
ls -la ./medicloudx_exporter_linux

echo ""
echo "📋 Para usar en Linux:"
echo "  chmod +x medicloudx_exporter_linux"
echo "  ./medicloudx_exporter_linux --version"
