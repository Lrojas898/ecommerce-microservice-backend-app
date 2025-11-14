#!/bin/bash
#
# Script para escanear todas las imágenes de servicios con Trivy
# Uso: ./scripts/scan-all-services.sh [tag] [severity]
#
# Ejemplos:
#   ./scripts/scan-all-services.sh                    # Escanea tag 'latest', severidad CRITICAL,HIGH
#   ./scripts/scan-all-services.sh v0.1.0             # Escanea tag específico
#   ./scripts/scan-all-services.sh latest CRITICAL    # Solo vulnerabilidades CRITICAL
#

set -e

# Configuración
DOCKER_USER="${DOCKER_USERNAME:-luisrojasc}"
TAG="${1:-latest}"
SEVERITY="${2:-CRITICAL,HIGH}"

SERVICES=(
  "service-discovery"
  "proxy-client"
  "user-service"
  "product-service"
  "order-service"
  "payment-service"
  "shipping-service"
  "favourite-service"
  "api-gateway"
)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar si Trivy está instalado
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}❌ Error: Trivy no está instalado${NC}"
    echo ""
    echo "Instalar Trivy:"
    echo "  Ubuntu/Debian: sudo apt-get install trivy"
    echo "  macOS: brew install aquasecurity/trivy/trivy"
    echo "  Más info: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    exit 1
fi

# Banner
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Trivy Security Scan - All Services${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "  Docker User: ${YELLOW}${DOCKER_USER}${NC}"
echo -e "  Tag:         ${YELLOW}${TAG}${NC}"
echo -e "  Severity:    ${YELLOW}${SEVERITY}${NC}"
echo -e "  Services:    ${YELLOW}${#SERVICES[@]}${NC}"
echo ""
echo -e "${BLUE}=========================================${NC}"
echo ""

# Crear directorio para reportes
REPORT_DIR="trivy-reports-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${REPORT_DIR}"

# Contadores
TOTAL_SERVICES=${#SERVICES[@]}
SCANNED=0
FAILED=0
VULNERABLE=0

# Escanear cada servicio
for service in "${SERVICES[@]}"; do
  SCANNED=$((SCANNED + 1))
  IMAGE="${DOCKER_USER}/${service}:${TAG}"

  echo -e "${BLUE}[${SCANNED}/${TOTAL_SERVICES}]${NC} 📦 Scanning ${YELLOW}${service}${NC}..."

  # Ejecutar escaneo
  REPORT_FILE="${REPORT_DIR}/${service}.txt"
  JSON_FILE="${REPORT_DIR}/${service}.json"

  if trivy image --severity "${SEVERITY}" --format table --output "${REPORT_FILE}" "${IMAGE}" 2>&1 | tee /tmp/trivy-output.txt; then
    # Generar también JSON para análisis
    trivy image --severity "${SEVERITY}" --format json --output "${JSON_FILE}" "${IMAGE}" > /dev/null 2>&1 || true

    # Contar vulnerabilidades
    if [ -f "${JSON_FILE}" ]; then
      CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
      HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
      MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
      TOTAL=$((CRITICAL + HIGH + MEDIUM))

      if [ "${TOTAL}" -gt 0 ]; then
        VULNERABLE=$((VULNERABLE + 1))
        echo -e "  ${RED}⚠️  Found: ${CRITICAL} CRITICAL, ${HIGH} HIGH, ${MEDIUM} MEDIUM${NC}"
      else
        echo -e "  ${GREEN}✅ No vulnerabilities found${NC}"
      fi
    else
      echo -e "  ${GREEN}✅ Scan completed${NC}"
    fi
  else
    FAILED=$((FAILED + 1))
    echo -e "  ${RED}❌ Scan failed${NC}"
    echo "Error details in /tmp/trivy-output.txt"
  fi

  echo ""
done

# Resumen final
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  SCAN SUMMARY${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "  Total services:        ${TOTAL_SERVICES}"
echo -e "  Successfully scanned:  ${GREEN}$((SCANNED - FAILED))${NC}"
echo -e "  Failed scans:          ${RED}${FAILED}${NC}"
echo -e "  With vulnerabilities:  ${YELLOW}${VULNERABLE}${NC}"
echo -e "  Clean:                 ${GREEN}$((SCANNED - FAILED - VULNERABLE))${NC}"
echo ""
echo -e "  Reports saved in:      ${YELLOW}${REPORT_DIR}/${NC}"
echo ""

# Generar reporte consolidado
SUMMARY_FILE="${REPORT_DIR}/SUMMARY.txt"
echo "Trivy Scan Summary" > "${SUMMARY_FILE}"
echo "=================" >> "${SUMMARY_FILE}"
echo "Date: $(date)" >> "${SUMMARY_FILE}"
echo "Tag: ${TAG}" >> "${SUMMARY_FILE}"
echo "Severity: ${SEVERITY}" >> "${SUMMARY_FILE}"
echo "" >> "${SUMMARY_FILE}"
echo "Results:" >> "${SUMMARY_FILE}"
echo "--------" >> "${SUMMARY_FILE}"

for service in "${SERVICES[@]}"; do
  JSON_FILE="${REPORT_DIR}/${service}.json"
  if [ -f "${JSON_FILE}" ]; then
    CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
    HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
    MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
    echo "${service}: CRITICAL=${CRITICAL}, HIGH=${HIGH}, MEDIUM=${MEDIUM}" >> "${SUMMARY_FILE}"
  fi
done

echo ""
echo -e "${GREEN}✓ Summary saved: ${SUMMARY_FILE}${NC}"
echo ""

# Mostrar servicios más vulnerables
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  TOP VULNERABLE SERVICES${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Crear archivo temporal con conteos
TEMP_COUNTS="/tmp/trivy-counts.txt"
> "${TEMP_COUNTS}"

for service in "${SERVICES[@]}"; do
  JSON_FILE="${REPORT_DIR}/${service}.json"
  if [ -f "${JSON_FILE}" ]; then
    CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
    HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "${JSON_FILE}" 2>/dev/null || echo "0")
    TOTAL=$((CRITICAL + HIGH))
    if [ "${TOTAL}" -gt 0 ]; then
      echo "${TOTAL} ${service} (${CRITICAL} CRITICAL, ${HIGH} HIGH)" >> "${TEMP_COUNTS}"
    fi
  fi
done

if [ -s "${TEMP_COUNTS}" ]; then
  sort -rn "${TEMP_COUNTS}" | head -5 | while read -r line; do
    echo "  ${line}"
  done
else
  echo -e "  ${GREEN}✨ All services are clean!${NC}"
fi

rm -f "${TEMP_COUNTS}"

echo ""
echo -e "${BLUE}=========================================${NC}"
echo ""

# Exit code basado en vulnerabilidades
if [ "${VULNERABLE}" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Action required: ${VULNERABLE} service(s) have vulnerabilities${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Review detailed reports in ${REPORT_DIR}/"
  echo "  2. Prioritize CRITICAL and HIGH severity issues"
  echo "  3. Update dependencies or base images"
  echo "  4. Re-run scan to verify fixes"
  echo ""
  exit 1
else
  echo -e "${GREEN}🎉 All services are secure!${NC}"
  echo ""
  exit 0
fi
