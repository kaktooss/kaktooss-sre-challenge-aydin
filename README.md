# Solution:

## Cluster:
- I used k3s as a lightwight k8s cluster with 1 node(control-plane+worker) and uses Traefik Ingress Controller and my OS is Ubuntu.
```
#deploy k3s
curl -sfL https://get.k3s.io | sh -
#kubeconfig when interacting k3s
export KUBECONFIG=$KUBECONFIG:/etc/rancher/k3s/k3s.yaml

kc get nodes
NAME        STATUS   ROLES           AGE   VERSION
sahina-vm   Ready    control-plane   37h   v1.36.5+k3s1

$ kc get svc -n kube-system
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
kube-dns         ClusterIP      10.43.0.10      <none>          53/UDP,53/TCP,9153/TCP       37h
metrics-server   ClusterIP      10.43.54.208    <none>          443/TCP                      37h
traefik          LoadBalancer   10.43.186.147   172.17.19.117   80:30350/TCP,443:32650/TCP   37h

```

## Automation:
- The solution is located in same parent path.
  - sre-challenge
  - sre-challenge-solution

- All solution can be run and automated in one script in "sre-challenge-solution" directory.
  ```
  ./install-all.sh
  ```
  - Note: (deploy-tool.sh - Installing java and mkcert tools are deployed and certs are created in this script. I commented it out if linux distribution is different from ubuntu. Please run it before install-all.sh script.)

## Scripts Definitions in install-all.sh
  
- Build Java and Docker Image Script.
  - ./build-java-docker.sh
  - java build, docker images build and uploaded to k3s registry.

- Deploy Kafka and Postgresql
  - ./deploy-kafka-postgresql.sh
  - deploy kafka and postgresql with single node and configuration for dev environment as helm charts. bitnamilegacy images are used because bitnami images are not available anymore as an open source.
  - nessessary postgres secret is created. (we do not have vault in this setup)
  - For kafka, zookeeper is deprecated and kraft is used.
  
- Deploy application front, back and reader
  - Three applications share most of the same YAML. So I used one generic "app-chart" chart (often called a Common Chart or Standard App Chart) is the standard approach in DevOps/SRE.
  - ./deploy-apps.sh
  - db users for back-app and reader-app is created with secrets defined.
  - TLS certs secrets are defined.
  - DB Job is run to grant permissions for back-app and reader-app
  - Updating local /etc/hosts for hosts (we do not have dns server in this setup)

## Uninstall All
- ./uninstall-all script can be used to delete all helm deployments.

## Architecture

```
+----------------------------------------------------------------------------------------------------+
| K8S Cluster                                                                                        |
|                                                                                                    |
|              +--------------------------------+                    +-----------------------------+ |
|              | NS: demo-front                 |                    | NS: demo-back               | |
|  +-------+   |    +-------+   +-------------+ |           Handle   |       +-------------+       | |
|  | Cloud |------> | HTTPS |-- | Front-App   | |                +---------> | Back-App    |       | |
|  +-------+   |    +-------+   | Port: 8080  | |                |   |       | Port: 8082  |       | |
|  Write Data  |                | Mgmt: 8081  | |                |   |       | Mgmt: 8081  |       | |
|              |                +------|------+ |                |   |       +------|------+       | |
|              +-----------------------|--------+                |   +--------------|--------------+ |
|                                      | Command                 |                  |                |
|                                      |    +--------------------|--+               | Write DB       |
|                                      |    | NS: kafka          |  |               |                |
|                                      |    |     +-------------+|  |               |                |
|                                      +--------> |    Kafka     |+ |               |                |
|                                           |     +------+------+   |               v                |
|                                           |            ^          |    +---------------------+     |
|                                           |            |          |    | NS: postgres        |     |
|                                           |     +------+------+   |    |     +-------------+ |     |
|                                           |     |  Kraft      |   |    |     | PostgreSQL  | <----+|
|                                           |     +-------------+   |    |     +-------------+ | |   |
|                                           +-----------------------+    +---------------------+ |   |
|                                                                                                |   |
|              +--------------------------------+                                                |   |
|              | NS: demo-reader                |                                                |   |
|  +-------+   |    +-------+   +-------------+ |                   Read DB                      |   |
|  | Cloud |------> | HTTPS |-- | Reader-App  | |------------------------------------------------+   |
|  +-------+   |    +-------+   | Port: 8084  | |                                                    |
|  Read Data   |                | Mgmt: 8081  | |                                                    |
|              |                +-------------+ |                                                    |
|              +--------------------------------+                                                    |
|                                                                                                    |
+----------------------------------------------------------------------------------------------------+
```

## Test Results:

- https endpoints:
  - https://demo-front.local/swagger-ui/index.html
  - https://demo-reader.local/swagger-ui/index.html

- Test result are located in test-screen-shots folder.
