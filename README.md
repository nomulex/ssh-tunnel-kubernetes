# SSH TUNNEL IN KUBERNETES

These files contain code that can help you create a cluster accessible ssh tunnel in Kubernetes using a Kubernetes service.  This is usually the case when you want to access databases that can only be authenticated through an ssh tunnel. The example files below refer to PostgreSQL

## Pre-requisites

1. You need to have an ssh key that you can install on the remote database server to authenticate your container through ssh and therefore establish the tunnel. You can generate your key using ssh-keygen.

```bash
#create your key folder
mkdir  -p keys
# Generate your keys
#You can ignore the passphrase and just press enter
ssh-keygen -o -a 100 -t ed25519 -f keys/id_ed25519 -C "autossh@fqdn.com"
```

This will generate a public-private key pair that you will need to use. Please do not use the keys in this repository they are just for example purposes. Create your own keys!

2. Create an autossh user on the remote database and add your public key there.

3. Add the private key in the deployment configmap

```yaml
 apiVersion: v1
kind: ConfigMap
metadata:
  name: autossh-private-key
data:
  #Add your super private key here. Replace the example below
  id_ed25519: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACAerY6uArVScgjH5C3xD7hHmfpm/l3Cnwhf7N6hO+Uh0wAAAJgQjI53EIyO
    dwAAAAtzc2gtZWQyNTUxOQAAACAerY6uArVScgjH5C3xD7hHmfpm/l3Cnwhf7N6hO+Uh0w
    AAAEAQmQmz1DybakU+NVW8IGF05AjWMx0BXl1Pp4enZmQqRR6tjq4CtVJyCMfkLfEPuEeZ
    +mb+XcKfCF/s3qE75SHTAAAAEGF1dG9zc2hAZnFkbi5jb20BAgMEBQ==
    -----END OPENSSH PRIVATE KEY-----
```

4. You can optionally build your own image or you can use one at [docker hub](https://hub.docker.com/r/nomulex/autossh).

## Environment Variables

### SSH_HOSTUSER

The user name of the ssh user that you created in the remote server.

## SSH_HOSTNAME

The fully qualified domain name of the host hosting the database resource that you want to access through the tunnel.  Example Postgres-host.fqdn.com

### SSH_TUNNEL_REMOTE

The remote port that you would like to expose to your cluster.

### SSH_TUNNEL_HOST

The remote host IP/URL that you want to expose.

### SSH_LOCAL_IP

This is the local interface IP through which we access the tunnel. It is ideally always localhost.

### SSH_TUNNEL_LOCAL

The local port that you will expose in your cluster.

### SSH_HOSTPORT

The ssh port through which you access ssh on the remote host. This is usually port 22 but could be different for your scenario.

### SSH_MODE

The ssh tunnel port forwarding mode ( our case is always local) `-L`. Read more about port forwarding [here](https://www.ssh.com/academy/ssh/tunneling/example).


## Traffic Control

Since exposing your remote host to your cluster increases the attack surface of your cluster. You can optionally create a [network policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: autossh-allow
  namespace: auto-ssh
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          autossh: allow
    ports:
    - protocol: TCP
      port: 5432

```

You need to add a label to your namespace that has resources that will access the service so that the network policy can allow ingress to the exposed service.

```YAML

  labels:
    autossh: allow
```

## Deploying to Kubernetes

1. Deploy your auto ssh pod and configmap.

```bash
kubectl create ns auto-ssh
kubectl apply -f config-map-private-key.yml
kubectl apply -f autossh-deployment.yml
```

2. Expose the deployment through a service

```bash
 kubectl apply -f  autossh-service.yml
```

3. Optionally apply a network policy to control traffic to your service.

```bash
kubectl apply -f autossh-networkpolicy.yml

```

## Accessing the tunnel.

Since you will have exposed the tunnel through a service, you can now access it in Kubernetes by using the service fqdn and port as the URL to your resource. For our example this would be `autossh-access.auto-ssh.svc.cluster.local:5432`. If you added a network policy, remember to label your namespace appropriately.

You can now access the remote resource as if it were local to your cluster. Kudos. For example, for Postgres, your URL would be `postgres://user:pass@autossh-access.auto-ssh.svc.cluster.local:5432/db
