# ELK Stack - Centralized Logging

**Universidad ICESI - Ingeniería de Software V**
**Proyecto**: E-Commerce Microservices Backend

---

## Descripción

Stack de logging centralizado para recolectar, almacenar y visualizar logs de todos los microservicios.

## Componentes

- **Elasticsearch 8.11.0**: Motor de búsqueda y almacenamiento de logs
- **Kibana 8.11.0**: UI para visualización y análisis de logs
- **Filebeat 8.11.0**: Recolector liviano de logs de containers

## Deployment Rápido

```bash
cd infrastructure/kubernetes/logging
chmod +x deploy-elk.sh
./deploy-elk.sh
```

## Acceso

**Kibana UI**:
```bash
# Opción 1: NodePort
minikube ip  # Luego abrir http://<minikube-ip>:30561

# Opción 2: Port-forward
kubectl port-forward -n logging svc/kibana 5601:5601
# Abrir: http://localhost:5601
```

**Elasticsearch API**:
```bash
kubectl port-forward -n logging svc/elasticsearch 9200:9200
curl http://localhost:9200/_cluster/health
```

## Primeros Pasos en Kibana

1. Abrir Kibana UI
2. Ir a **Management** → **Stack Management** → **Index Patterns**
3. Crear index pattern: `ecommerce-logs-*`
4. Seleccionar timestamp field: `@timestamp`
5. Ir a **Analytics** → **Discover** para ver logs

## Queries Útiles

**Filtrar por servicio**:
```
kubernetes.labels.app: "user-service"
```

**Filtrar por namespace**:
```
kubernetes.namespace: "prod"
```

**Buscar errores**:
```
level: "ERROR"
```

## Verificación

```bash
# Ver recursos
kubectl get all -n logging

# Ver índices en Elasticsearch
kubectl exec -n logging deployment/elasticsearch -- \
  curl -s http://localhost:9200/_cat/indices?v

# Ver logs de Filebeat
kubectl logs -n logging daemonset/filebeat --tail=50
```

## Archivos

- `namespace.yaml`: Namespace de logging
- `elasticsearch.yaml`: Deployment de Elasticsearch
- `kibana.yaml`: Deployment de Kibana
- `filebeat-config.yaml`: Configuración de Filebeat
- `filebeat.yaml`: DaemonSet de Filebeat
- `deploy-elk.sh`: Script de deployment automatizado
