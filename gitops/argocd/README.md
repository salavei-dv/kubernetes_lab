# ArgoCD Configuration

## Доступ к ArgoCD UI

- **URL**: https://192.168.56.10:31104 (HTTPS) или http://192.168.56.10:31748 (HTTP)
- **Логин**: admin
- **Пароль**: 2yk9vfO-FXJtlxdZ

## Структура

- `app-of-apps.yaml` - основное приложение для управления всеми остальными
- `applications/` - директория с конфигурациями отдельных приложений

## Применение конфигураций

```bash
# Применить App of Apps
kubectl apply -f gitops/argocd/app-of-apps.yaml

# Или применить отдельные приложения
kubectl apply -f gitops/argocd/applications/
```

## Полезные команды

```bash
# Проверить статус приложений
kubectl get applications -n argocd

# Синхронизировать приложение
kubectl patch application vault -n argocd --type merge -p '{"operation":{"sync":{}}}'
```
