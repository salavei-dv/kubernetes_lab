# Kubernetes Lab

## Структура проекта

```text
kubernetes_lab/
├── infrastructure/           # Инфраструктурные компоненты
│   ├── vagrant/             # Vagrant скрипты и конфигурации
│   ├── network/             # Сетевые плагины (Flannel)
│   └── storage/             # Конфигурации хранилища
├── applications/            # Приложения Kubernetes
│   ├── vault/              # HashiCorp Vault
│   └── monitoring/         # Мониторинг (Grafana, etc.)
├── helm-charts/            # Helm чарты
├── gitops/                 # GitOps конфигурации
│   ├── flux/              # Flux CD (legacy)
│   └── argocd/            # ArgoCD
└── tools/                  # Вспомогательные инструменты
```

## Создание кластера Kubernetes с Vagrant

Запуск кластера (включает автоматическую установку Flannel):

```shell
vagrant up
```

Копирование config для kubectl на хостовую машину:

```shell
vagrant ssh controlplane -c "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config
```

## Установка сетевого плагина Flannel

Flannel устанавливается автоматически при создании кластера. Для ручной установки:

```shell
kubectl apply -k infrastructure/network/flannel-config/
```

## Настройка kubectl

Скопировать config для kubectl на хостовую машину:

```shell
    vagrant ssh controlplane -c "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config
```

Установка динамического хранилища.

```shell
    helm install nfs-subdir-external-provisioner \
    nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.56.50 \
    --set nfs.path=/srv/nfs/kubedata \
    -n nfs-subdir-external-provisioner --create-namespace
```

## Vault

```yaml
# applications/vault/vault-dev-values.yaml
global:
  # Обязательный параметр
  openshift: false

# Включаем и настраиваем пользовательский интерфейс Vault
ui:
  enabled: true
  # Используем NodePort, чтобы получить доступ к UI извне кластера (с нашего хост-компьютера)
  serviceType: "NodePort" 

server:
  # Включаем режим разработки. Это ключ к простой установке!
  dev:
    enabled: true

  # Даже в dev-режиме, мы хотим, чтобы Helm создал для нас StatefulSet,
  # что является хорошей практикой. Для этого мы включаем HA (High Availability)
  # и выбираем встроенное хранилище Raft.
  ha:
    enabled: true
    raft:
      enabled: true

```

Устанавливаем чарт

```shell
helm install vault hashicorp/vault \
  --namespace vault \
  -f ./applications/vault/vault-dev-values.yaml \
  --create-namespace
```

Извлеч **Root Token**
`kubectl logs -n vault vault-0`

Metrics Server

`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

## ArgoCD

Установка ArgoCD:

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
```

Получить пароль администратора:

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Получить порт для доступа к UI:

```shell
kubectl get svc argocd-server -n argocd
```

### Настройка GitOps

Применить конфигурации приложений:

```shell
kubectl apply -f gitops/argocd/applications/
```

Доступ к ArgoCD UI:
- URL: https://192.168.56.10:31104 (HTTPS) или http://192.168.56.10:31748 (HTTP)
- Логин: `admin`
- Пароль: получить командой выше

### Структура GitOps

```text
gitops/argocd/
├── README.md              # Документация ArgoCD
├── app-of-apps.yaml      # Главное приложение для управления всеми
└── applications/         # Конфигурации отдельных приложений
    └── vault.yaml        # Пример приложения для Vault
```
