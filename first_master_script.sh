# Using Curl to install RKE2 but not starting it. We are secifying the version. 

echo "installing RKE2. If this fails check your repos that are enabled"
curl -sfL https://get.rke2.io |  INSTALL_RKE2_VERSION="v1.25.16+rke2r1" sh -

# enabling the service so when a reboot happens rke2 restarts
echo "enabling the rke2 service"
systemctl enable rke2-server

# applying hardening and STIG 
echo "setting up etcd user and applying sysctl"
useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
cp -f /usr/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
systemctl restart systemd-sysctl

# STIG config cont and specifying token for other nodes to join cluster. 
echo "setting up the rke2 config.yaml"
mkdir -p /etc/rancher/rke2/ /var/lib/rancher/rke2/server/manifests/
echo "token: ${1}" > /etc/rancher/rke2/config.yaml
echo -e "#profile: cis-1.23\nselinux: true\nsecrets-encryption: true\nwrite-kubeconfig-mode: 0600\nkube-controller-manager-arg:\n- bind-address=127.0.0.1\n- use-service-account-credentials=true\n- tls-min-version=VersionTLS12\n- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\nkube-scheduler-arg:\n- tls-min-version=VersionTLS12\n- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\nkube-apiserver-arg:\n- tls-min-version=VersionTLS12\n- tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\n- authorization-mode=RBAC,Node\n- anonymous-auth=false\n#- audit-policy-file=/etc/rancher/rke2/audit-policy.yaml\n- audit-log-mode=blocking-strict\n- audit-log-maxage=30\nkubelet-arg:\n- protect-kernel-defaults=true\n- read-only-port=0\n- authorization-mode=Webhook" >>/etc/rancher/rke2/config.yaml

# setting up kubectl 
echo "setting up kubectl"
echo 'PATH=${PATH}:/var/lib/rancher/rke2/bin:/usr/local/bin' >> ~/.bashrc
mkdir ~/.kube

# disabling firewalld. you can reenable if you specify the ports to be open. https://docs.rke2.io/known_issues?_highlight=firewalld#firewalld-conflicts-with-default-networking
echo "disabling firewalld"
systemctl disable firewalld
systemctl stop firewalld

# adding network config https://docs.rke2.io/known_issues?_highlight=known
echo "adding a network config"
echo -e "[keyfile]\nunmanaged-devices=interface-name:cali*;interface-name:flannel*" > /etc/NetworkManager/conf.d/rke2-canal.conf
systemctl reload NetworkManager

# Starting rke2 Server
echo "starting rke2 service"
systemctl start rke2-server

# Installing helm so we can install rancher later 
echo "setting up helm"
cat /etc/rancher/rke2/rke2.yaml > ~/.kube/config
chmod 600 ~/.kube/config
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
