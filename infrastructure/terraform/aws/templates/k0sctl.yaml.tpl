apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0rdent-cluster
spec:
  hosts:
    %{ for index, ip in controller_ips ~}
    - ssh:
        address: ${ip}
        user: ubuntu
        port: 22
        keyPath: ${ssh_key_path}
      role: controller
      %{ if index == 0 ~}
      installFlags:
        - --enable-worker
      %{ endif ~}
    %{ endfor ~}
    %{ for ip in worker_ips ~}
    - ssh:
        address: ${ip}
        user: ubuntu
        port: 22
        keyPath: ${ssh_key_path}
      role: worker
    %{ endfor ~}
  k0s:
    version: ${k0s_version}
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: ClusterConfig
      metadata:
        name: k0s
      spec:
        api:
          externalAddress: ${controller_ips[0]}
          sans:
            - ${controller_ips[0]}
        network:
          provider: kuberouter
          podCIDR: 10.244.0.0/16
          serviceCIDR: 10.96.0.0/12
        storage:
          type: etcd
        telemetry:
          enabled: false