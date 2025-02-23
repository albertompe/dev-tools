#!/bin/bash

script_name=$0
SCRIPT=$(readlink -f $script_name)
BASEDIR=$(dirname $SCRIPT)
BUNDLESDIR=$BASEDIR/bundles
BINDIR=$BASEDIR/bin

function usage {
    echo "Retrieves and generates the distributable of the bundle specified"
    echo "  Usage: $script_name <bundle_or_package_name>"
    echo "         $script_name all # Retrieves the las version of all bundles"
    echo "Bundles available:"
    echo "  git            - Installs Git SCM from source code using the latest version"
    echo "  maven          - Installs the latest version of Apache Maven"
    echo "  ant            - Installs the latest version of Apache Ant"
    echo "  docker-compose - Docker compose"
    echo "  minikube       - Minikube"
    echo "  kubectl        - Kubectl"
    echo "  kubectx        - Kubectx"
    echo "  kubens         - Kubens"
    echo "  k3sup          - K3sup"
    echo "  k3d            - K3d"
    echo "  kind           - Kind"
    echo "  knative        - Knative"
    echo "  terraform      - Terraform"
    echo "  yq             - yq"
    echo "  conftest       - conftest"
    echo "  kubeconform    - kubeconform"
    echo "  oc             - Openshift v4 CLI"
    echo "  opm            - OpenShift v4 OPM CLI"
    echo "  gh             - GitHub CLI"
    echo "  operator-sdk   - Operator SDK"
    echo "  kustomize      - Kustomize"
    echo "  kubelogin      - Azure Kubelogin"
    echo "  helm           - Helm"
    echo "  k9s            - K9s"
    echo "  redis-cli      - redis-cli"
    echo "  velero         - velero"
    echo "  krew           - krew"
    echo "  krew-krew      - krew plugin"
    echo "  krew-profefe   - krew profefe plugin"
    echo "  krew-neat      - krew neat plugin"
    echo "  krew-rabbitmq  - krew rabbitmq plugin"
    echo "  kubebuilder    - Kubebuilder"
}

function git_install {
    echo "Git scm bundle generation"

    # Recreate tmp working dir
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd $tmpDir

    # Clone git repo and choose the latest released version
    git clone https://github.com/git/git.git
    cd git
    git fetch --tags
    tag=$(git tag -l --sort=-v:refname | grep -oP '^v[0-9\.]+$' | head -n 1)

    # Arch x86_64 is replaced by amd64
    git_arch=$ARCH
    [ $ARCH = 'x86_64' ] && git_arch='amd64'

    # Check if already installed
    [ -d $BUNDLESDIR/git/git-$tag-$PLATFORM-$git_arch ] && echo "Git version ${tag} already installed!" && rm -rf $tmpDir && unset tmpDir && return
    [[ ! -d $BUNDLESDIR/git ]] && mkdir -p $BUNDLESDIR/git

    # Configure, build and install
    git checkout $tag -b version-to-install
    make configure
    ./configure --prefix=$BUNDLESDIR/git/git-$tag-$PLATFORM-$git_arch
    make all
    make install

    # Set the default version
    rm -f $BUNDLESDIR/git/default-$PLATFORM-$git_arch
    ln -s git-$tag-$PLATFORM-$git_arch $BUNDLESDIR/git/default-$PLATFORM-$git_arch

    # Link 

    unset git_arch
    unset tmpDir
}

function maven_install {
    echo "Maven installation"

    # Find latest version
    echo "Finding latest version of Apache Maven..."
    latest="$(wget -qO- https://dlcdn.apache.org/maven/maven-3/ | grep -oP '[0-9\.]+/<' | grep -oP '[0-9\.]+' | tail -n 1)"

    # Check if already installed
    [ -d $BUNDLESDIR/apache-maven/apache-maven-"${latest}" ] && echo "Apache Maven version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/apache-maven ]] && mkdir -p $BUNDLESDIR/apache-maven

    # Download Apache Maven
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest Apache Maven: ${latest}"
    wget --quiet --continue --show-progress https://dlcdn.apache.org/maven/maven-3/"${latest}"/binaries/apache-maven-"${latest}"-bin.tar.gz
    unset url

    tar -C $BUNDLESDIR/apache-maven -xzf apache-maven-"${latest}"-bin.tar.gz

    # Set the default version
    rm -f $BUNDLESDIR/apache-maven/default
    ln -s apache-maven-"${latest}" $BUNDLESDIR/apache-maven/default

    unset tmpDir
}

function ant_install {
    echo "Ant installation"

    # Find latest version
    echo "Finding latest version of Apache Ant..."
    latest="$(wget -qO- http://apache.uvigo.es//ant/binaries/ | grep -oP 'apache-ant-([0-9\.]+)-bin.tar.gz<' | grep -oP 'ant-[0-9\.]+' | grep -oP '[0-9\.]+' | sort --version-sort | tail -n 1)"

    # Check if already installed
    [ -d $BUNDLESDIR/apache-ant/apache-ant-"${latest}" ] && echo "Apache Ant version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/apache-ant ]] && mkdir -p $BUNDLESDIR/apache-ant

    # Download Apache Ant
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest Apache Ant: ${latest}"
    wget --quiet --continue --show-progress http://apache.uvigo.es//ant/binaries/apache-ant-"${latest}"-bin.tar.gz
    unset url

    tar -C $BUNDLESDIR/apache-ant -xzf apache-ant-"${latest}"-bin.tar.gz

    # Set the default version
    rm -f $BUNDLESDIR/apache-ant/default
    ln -s apache-ant-"${latest}" $BUNDLESDIR/apache-ant/default

    unset tmpDir
}

function docker_compose_install {
    echo "Docker compose install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    docker_compose_arch=$ARCH
    [ $ARCH = 'x86_64' ] && docker_compose_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/docker-compose/docker-compose-${latest}-$PLATFORM-${docker_compose_arch} ] && echo "Docker compose version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/docker-compose ]] && mkdir -p $BUNDLESDIR/docker-compose

    # Download docker compose
    echo "Installing docker compose version ${latest}"
    curl -L "https://github.com/docker/compose/releases/download/${latest}/docker-compose-$PLATFORM-$ARCH" -o $BUNDLESDIR/docker-compose/docker-compose-${latest}-$PLATFORM-${docker_compose_arch}
    chmod +x $BUNDLESDIR/docker-compose/docker-compose-${latest}-$PLATFORM-${docker_compose_arch}

    # Set the default version
    rm -f $BUNDLESDIR/docker-compose/default-$PLATFORM-${docker_compose_arch}
    ln -s docker-compose-$latest-$PLATFORM-${docker_compose_arch} $BUNDLESDIR/docker-compose/default-$PLATFORM-${docker_compose_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${docker_compose_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${docker_compose_arch}
    [[ ! -f $BINDIR/$PLATFORM-${docker_compose_arch}/docker-compose ]] && ln -s ../../bundles/docker-compose/default-$PLATFORM-${docker_compose_arch} $BINDIR/$PLATFORM-${docker_compose_arch}/docker-compose

    unset docker_compose_arch
    unset latest
}

function minikube_install {
    echo "Minikube install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    minikube_arch=$ARCH
    [ $ARCH = 'x86_64' ] && minikube_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/minikube/minikube-${latest}-$PLATFORM-${minikube_arch} ] && echo "Minikube version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/minikube ]] && mkdir -p $BUNDLESDIR/minikube

    # Download minikube
    echo "Installing minikube version ${latest}"    
    curl -L "https://github.com/kubernetes/minikube/releases/download/${latest}/minikube-$PLATFORM-${minikube_arch}" -o $BUNDLESDIR/minikube/minikube-${latest}-$PLATFORM-${minikube_arch}
    chmod +x $BUNDLESDIR/minikube/minikube-${latest}-$PLATFORM-$minikube_arch

    # Set the default version
    rm -f $BUNDLESDIR/minikube/default-$PLATFORM-${minikube_arch}
    ln -s minikube-$latest-$PLATFORM-${minikube_arch} $BUNDLESDIR/minikube/default-$PLATFORM-${minikube_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${minikube_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${minikube_arch}
    [[ ! -f $BINDIR/$PLATFORM-${minikube_arch}/minikube ]] && ln -s ../../bundles/minikube/default-$PLATFORM-${minikube_arch} $BINDIR/$PLATFORM-${minikube_arch}/minikube

    unset minikube_arch
    unset latest
}

function kubectl_install {
    # https://kubernetes.io/releases/download/#kubectl
    echo "Kubectl install"

    # Find latest version
    latest=$(curl -L -s https://dl.k8s.io/release/stable.txt)

    # Arch x86_64 replaced by amd64
    kubectl_arch=$ARCH
    [ $ARCH == 'x86_64' ] && kubectl_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubectl/kubectl-${latest}-$PLATFORM-${kubectl_arch} ] && echo "Kubectl version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kubectl ]] && mkdir -p $BUNDLESDIR/kubectl

    # Download kubectl
    echo "Installing kubectl version ${latest}"
    curl -L "https://dl.k8s.io/release/${latest}/bin/$PLATFORM/${kubectl_arch}/kubectl" -o $BUNDLESDIR/kubectl/kubectl-${latest}-$PLATFORM-${kubectl_arch}
    chmod +x $BUNDLESDIR/kubectl/kubectl-${latest}-$PLATFORM-${kubectl_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kubectl/default-$PLATFORM-${kubectl_arch}
    ln -s kubectl-${latest}-$PLATFORM-${kubectl_arch} $BUNDLESDIR/kubectl/default-$PLATFORM-${kubectl_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubectl_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubectl_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubectl_arch}/kubectl ]] && ln -s ../../bundles/kubectl/default-$PLATFORM-${kubectl_arch} $BINDIR/$PLATFORM-${kubectl_arch}/kubectl

    unset kubectl_arch
    unset latest
}

function kubectx_install {
    echo "Kubectx install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    kubectx_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kubectx_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubectx/kubectx-${latest}-$PLATFORM-${kubectx_arch} ] && echo "Kubectx version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kubectx ]] && mkdir -p $BUNDLESDIR/kubectx

    # Download kubectx
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Installing kubectx version ${latest}"
    wget "https://github.com/ahmetb/kubectx/releases/download/${latest}/kubectx_${latest}_${PLATFORM}_$ARCH.tar.gz"
    tar xzvf kubectx_${latest}_${PLATFORM}_$ARCH.tar.gz
    mv kubectx $BUNDLESDIR/kubectx/kubectx-${latest}-$PLATFORM-${kubectx_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kubectx/default-$PLATFORM-${kubectx_arch}
    ln -s kubectx-$latest-$PLATFORM-${kubectx_arch} $BUNDLESDIR/kubectx/default-$PLATFORM-${kubectx_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubectx_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubectx_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubectx_arch}/kubectx ]] && ln -s ../../bundles/kubectx/default-$PLATFORM-${kubectx_arch} $BINDIR/$PLATFORM-${kubectx_arch}/kubectx

    unset tmpDir
    unset kubectx_arch
    unset latest
}

function kubens_install {
    echo "Kubens install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    kubens_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kubens_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubens/kubens-${latest}-$PLATFORM-${kubens_arch} ] && echo "kubens version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kubens ]] && mkdir -p $BUNDLESDIR/kubens

    # Download kubens
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Installing kubens version ${latest}"
    wget "https://github.com/ahmetb/kubectx/releases/download/${latest}/kubens_${latest}_${PLATFORM}_$ARCH.tar.gz"
    tar xzvf kubens_${latest}_${PLATFORM}_$ARCH.tar.gz
    mv kubens $BUNDLESDIR/kubens/kubens-${latest}-$PLATFORM-${kubens_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kubens/default-$PLATFORM-${kubens_arch}
    ln -s kubens-$latest-$PLATFORM-${kubens_arch} $BUNDLESDIR/kubens/default-$PLATFORM-${kubens_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubens_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubens_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubens_arch}/kubens ]] && ln -s ../../bundles/kubens/default-$PLATFORM-${kubens_arch} $BINDIR/$PLATFORM-${kubens_arch}/kubens

    unset tmpDir
    unset kubens_arch
    unset latest
}

function k3sup_install {
    echo "K3sup install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/alexellis/k3sup/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Filenames
    k3sup_arch=$ARCH
    [ $ARCH = 'x86_64' ] && k3sup_arch='amd64'
    k3sup_bin_name=k3sup
    [ $PLATFORM != 'linux' ] && k3sup_bin_name=${k3sup_bin_name}-$PLATFORM
    [ $ARCH != 'x86_64' ] && k3sup_bin_name=${k3sup_bin_name}-$ARCH
    k3sup_dest_name=k3sup-v${latest}-$PLATFORM-${k3sup_arch}

    # Check if already installed
    [ -f $BUNDLESDIR/k3sup/${k3sup_dest_name} ] && echo "V3sup version v${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/k3sup ]] && mkdir -p $BUNDLESDIR/k3sup

    # Download kubectl
    echo "Installing K3sup version v${latest}"
    curl -L "https://github.com/alexellis/k3sup/releases/download/${latest}/${k3sup_bin_name}" -o $BUNDLESDIR/k3sup/${k3sup_dest_name}
    chmod +x $BUNDLESDIR/k3sup/${k3sup_dest_name}

    # Set the default version
    rm -f $BUNDLESDIR/k3sup/default-$PLATFORM-${k3sup_arch}
    ln -s ${k3sup_dest_name} $BUNDLESDIR/k3sup/default-$PLATFORM-${k3sup_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${k3sup_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${k3sup_arch}
    [[ ! -f $BINDIR/$PLATFORM-${k3sup_arch}/k3sup ]] && ln -s ../../bundles/k3sup/default-$PLATFORM-${k3sup_arch} $BINDIR/$PLATFORM-${k3sup_arch}/k3sup

    unset k3sup_bin_name
    unset k3sup_dest_name
    unset kubectl_arch
    unset latest
}

function k3d_install {
    echo "K3d install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/k3d-io/k3d/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    k3d_arch=$ARCH
    [ $ARCH = 'x86_64' ] && k3d_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/k3d/k3d-${latest}-$PLATFORM-${k3d_arch} ] && echo "K3d version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/k3d ]] && mkdir -p $BUNDLESDIR/k3d

    # Download k3d
    echo "Installing k3d version ${latest}"    
    curl -L "https://github.com/k3d-io/k3d/releases/download/${latest}/k3d-$PLATFORM-${k3d_arch}" -o $BUNDLESDIR/k3d/k3d-${latest}-$PLATFORM-${k3d_arch}
    chmod +x $BUNDLESDIR/k3d/k3d-${latest}-$PLATFORM-$k3d_arch

    # Set the default version
    rm -f $BUNDLESDIR/k3d/default-$PLATFORM-${k3d_arch}
    ln -s k3d-$latest-$PLATFORM-${k3d_arch} $BUNDLESDIR/k3d/default-$PLATFORM-${k3d_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${k3d_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${k3d_arch}
    [[ ! -f $BINDIR/$PLATFORM-${k3d_arch}/k3d ]] && ln -s ../../bundles/k3d/default-$PLATFORM-${k3d_arch} $BINDIR/$PLATFORM-${k3d_arch}/k3d

    unset k3d_arch
    unset latest
}

function kind_install {
    echo "Kind install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    kind_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kind_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kind/kind-${latest}-$PLATFORM-${kind_arch} ] && echo "Kind version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kind ]] && mkdir -p $BUNDLESDIR/kind

    # Download kind
    echo "Installing kind version ${latest}"    
    curl -L "https://github.com/kubernetes-sigs/kind/releases/download/${latest}/kind-$PLATFORM-${kind_arch}" -o $BUNDLESDIR/kind/kind-${latest}-$PLATFORM-${kind_arch}
    chmod +x $BUNDLESDIR/kind/kind-${latest}-$PLATFORM-$kind_arch

    # Set the default version
    rm -f $BUNDLESDIR/kind/default-$PLATFORM-${kind_arch}
    ln -s kind-$latest-$PLATFORM-${kind_arch} $BUNDLESDIR/kind/default-$PLATFORM-${kind_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kind_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kind_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kind_arch}/kind ]] && ln -s ../../bundles/kind/default-$PLATFORM-${kind_arch} $BINDIR/$PLATFORM-${kind_arch}/kind

    unset kind_arch
    unset latest
}

function knative_install {
    echo "Knative install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/knative/client/releases/latest | grep 'tag_name' | cut -d\" -f4 | awk -F- '{ print $2 }')

    # Arch x86_64 replaced by amd64
    kn_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kn_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/knative/kn-${latest}-$PLATFORM-${kn_arch} ] && echo "Knative version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/knative ]] && mkdir -p $BUNDLESDIR/knative

    # Download Knative
    echo "Installing kn version ${latest}"    
    curl -L "https://github.com/knative/client/releases/download/knative-${latest}/kn-$PLATFORM-${kn_arch}" -o $BUNDLESDIR/knative/kn-${latest}-$PLATFORM-${kn_arch}
    chmod +x $BUNDLESDIR/knative/kn-${latest}-$PLATFORM-$kn_arch

    # Set the default version
    rm -f $BUNDLESDIR/knative/default-$PLATFORM-${kn_arch}
    ln -s kn-$latest-$PLATFORM-${kn_arch} $BUNDLESDIR/knative/default-$PLATFORM-${kn_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kn_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kn_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kn_arch}/kn ]] && ln -s ../../bundles/knative/default-$PLATFORM-${kn_arch} $BINDIR/$PLATFORM-${kn_arch}/kn

    unset kn_arch
    unset latest
}

function terraform_install {
    echo "Terraform install"

    # Get the latest version
    latest=$(wget -qO- https://releases.hashicorp.com/terraform/ | grep -oP 'terraform_[0-9\.]+<' | grep -oP 'terraform_[0-9.]+' | grep -oP '[0-9\.]+' | head -n 1)

    # Arch x86_64 replaced by amd64
    terraform_arch=$ARCH
    [ $ARCH = 'x86_64' ] && terraform_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/terraform/terraform-v${latest}-$PLATFORM-${kubens_arch} ] && echo "Terraform version v${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/terraform ]] && mkdir -p $BUNDLESDIR/terraform

    # Download terraform
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest Terraform version: v${latest}"
    wget --quiet --continue --show-progress https://releases.hashicorp.com/terraform/${latest}/terraform_${latest}_${PLATFORM}_${terraform_arch}.zip
    unzip terraform_${latest}_${PLATFORM}_${terraform_arch}.zip

    mv terraform $BUNDLESDIR/terraform/terraform-${latest}-$PLATFORM-${terraform_arch}

    # Set the default version
    rm -f $BUNDLESDIR/terraform/default-$PLATFORM-${terraform_arch}
    ln -s terraform-$latest-$PLATFORM-${terraform_arch} $BUNDLESDIR/terraform/default-$PLATFORM-${terraform_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${terraform_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${terraform_arch}
    [[ ! -f $BINDIR/$PLATFORM-${terraform_arch}/terraform ]] && ln -s ../../bundles/terraform/default-$PLATFORM-${terraform_arch} $BINDIR/$PLATFORM-${terraform_arch}/terraform

    unset tmpDir
    unset terraform_arch
    unset latest
}

function yq_install {
    echo "yq install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    yq_arch=$ARCH
    [ $ARCH = 'x86_64' ] && yq_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/yq/yq-${latest}-$PLATFORM-${yq_arch} ] && echo "yq version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/yq ]] && mkdir -p $BUNDLESDIR/yq

    # Download yq
    echo "Installing yq version ${latest}"    
    curl -L "https://github.com/mikefarah/yq/releases/download/${latest}/yq_${PLATFORM}_${yq_arch}" -o $BUNDLESDIR/yq/yq-${latest}-$PLATFORM-${yq_arch}
    chmod +x $BUNDLESDIR/yq/yq-${latest}-$PLATFORM-$yq_arch

    # Set the default version
    rm -f $BUNDLESDIR/yq/default-$PLATFORM-${yq_arch}
    ln -s yq-$latest-$PLATFORM-${yq_arch} $BUNDLESDIR/yq/default-$PLATFORM-${yq_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${yq_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${yq_arch}
    [[ ! -f $BINDIR/$PLATFORM-${yq_arch}/yq ]] && ln -s ../../bundles/yq/default-$PLATFORM-${yq_arch} $BINDIR/$PLATFORM-${yq_arch}/yq

    unset yq_arch
    unset latest
}

function conftest_install {
    echo "conftest install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/open-policy-agent/conftest/releases/latest | grep 'tag_name' | cut -d\" -f4)
    latest_package=$(echo ${latest} | cut -c 2-)

    # Arch x86_64 used in package names
    conftest_arch_package=$ARCH
    [ $ARCH = 'x86_64' ] && conftest_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/conftest/conftest-${latest}-$PLATFORM-${conftest_arch} ] && echo "conftest version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/conftest ]] && mkdir -p $BUNDLESDIR/conftest

    # Download conftest
    platform_package="$(tr '[:lower:]' '[:upper:]' <<< ${PLATFORM:0:1})${PLATFORM:1}"
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest conftest version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/open-policy-agent/conftest/releases/download/${latest}/conftest_${latest_package}_${platform_package}_${conftest_arch_package}.tar.gz
    tar xzvf conftest_${latest_package}_${platform_package}_${conftest_arch_package}.tar.gz

    mv conftest $BUNDLESDIR/conftest/conftest-${latest}-$PLATFORM-${conftest_arch}

    # Set the default version
    rm -f $BUNDLESDIR/conftest/default-$PLATFORM-${conftest_arch}
    ln -s conftest-$latest-$PLATFORM-${conftest_arch} $BUNDLESDIR/conftest/default-$PLATFORM-${conftest_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${conftest_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${conftest_arch}
    [[ ! -f $BINDIR/$PLATFORM-${conftest_arch}/conftest ]] && ln -s ../../bundles/conftest/default-$PLATFORM-${conftest_arch} $BINDIR/$PLATFORM-${conftest_arch}/conftest

    unset platform_package
    unset tmpDir
    unset conftest_arch
    unset latest
}

function kubeconform_install {
    echo "kubeconform install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/yannh/kubeconform/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 used in package names
    kubeconform_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kubeconform_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubeconform/kubeconform-${latest}-$PLATFORM-${kubeconform_arch} ] && echo "kubeconform version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kubeconform ]] && mkdir -p $BUNDLESDIR/kubeconform

    # Download kubeconform
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest kubeconform version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/yannh/kubeconform/releases/download/${latest}/kubeconform-${PLATFORM}-${kubeconform_arch}.tar.gz
    tar xzvf kubeconform-${PLATFORM}-${kubeconform_arch}.tar.gz

    mv kubeconform $BUNDLESDIR/kubeconform/kubeconform-${latest}-$PLATFORM-${kubeconform_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kubeconform/default-$PLATFORM-${kubeconform_arch}
    ln -s kubeconform-$latest-$PLATFORM-${kubeconform_arch} $BUNDLESDIR/kubeconform/default-$PLATFORM-${kubeconform_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubeconform_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubeconform_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubeconform_arch}/kubeconform ]] && ln -s ../../bundles/kubeconform/default-$PLATFORM-${kubeconform_arch} $BINDIR/$PLATFORM-${kubeconform_arch}/kubeconform

    unset tmpDir
    unset kubeconform_arch
    unset latest
}

function oc_install {
    echo "Openshift CLI install"

    # Arch x86_64 used in package names
    oc_arch=$ARCH
    [ $ARCH = 'x86_64' ] && oc_arch='amd64'

    # Download oc
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest oc version"
    wget --quiet --continue --show-progress https://mirror.openshift.com/pub/openshift-v4/${oc_arch}/clients/oc/latest/${PLATFORM}/oc.tar.gz
    tar xzvf oc.tar.gz
    latest=$($tmpDir/oc version | grep "Client Version:" | awk '{ print $3 }')

    # Check if already installed
    [ -f $BUNDLESDIR/oc/oc-${latest}-$PLATFORM-${oc_arch}* ] && echo "oc version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/oc ]] && mkdir -p $BUNDLESDIR/oc

    mv oc oc-${latest}-$PLATFORM-${oc_arch}
    mv oc-${latest}-$PLATFORM-${oc_arch} $BUNDLESDIR/oc

    # Set the default version
    rm -f $BUNDLESDIR/oc/default-$PLATFORM-${oc_arch}
    ln -s oc-$latest-$PLATFORM-${oc_arch} $BUNDLESDIR/oc/default-$PLATFORM-${oc_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${oc_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${oc_arch}
    [[ ! -f $BINDIR/$PLATFORM-${oc_arch}/oc ]] && ln -s ../../bundles/oc/default-$PLATFORM-${oc_arch} $BINDIR/$PLATFORM-${oc_arch}/oc

    unset tmpDir
    unset oc_arch
    unset latest
}

function opm_install {
    echo "Openshift OPM CLI install"

    # Arch x86_64 used in package names
    opm_arch=$ARCH
    [ $ARCH = 'x86_64' ] && opm_arch='amd64'

    # Download oc
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest oc version"
    wget --quiet --continue --show-progress https://mirror.openshift.com/pub/openshift-v4/${opm_arch}/clients/ocp/latest/opm-${PLATFORM}.tar.gz
    tar xzvf opm-${PLATFORM}.tar.gz
    latest=$($tmpDir/opm-rhel8 version | awk '{ print $2 }' | awk -F: '{ print $2 }' | awk -F'"' '{ print $2 }')

    # Check if already installed
    [ -f $BUNDLESDIR/opm/opm-${latest}-$PLATFORM-${opm_arch}* ] && echo "opm version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/opm ]] && mkdir -p $BUNDLESDIR/opm

    mv opm-rhel8 opm-${latest}-$PLATFORM-${opm_arch}
    mv opm-${latest}-$PLATFORM-${opm_arch} $BUNDLESDIR/opm

    # Set the default version
    rm -f $BUNDLESDIR/opm/default-$PLATFORM-${opm_arch}
    ln -s opm-$latest-$PLATFORM-${opm_arch} $BUNDLESDIR/opm/default-$PLATFORM-${opm_arch}

    # # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${opm_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${opm_arch}
    [[ ! -f $BINDIR/$PLATFORM-${opm_arch}/opm ]] && ln -s ../../bundles/opm/default-$PLATFORM-${opm_arch} $BINDIR/$PLATFORM-${opm_arch}/opm

    unset tmpDir
    unset opm_arch
    unset latest
}

function gh_install {
    echo "GitHub CLI install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep 'tag_name' | cut -d\" -f4)
    latest_filename=$(echo $latest | awk -Fv '{ print $2 }')

    # Arch x86_64 used in package names
    gh_arch=$ARCH
    [ $ARCH = 'x86_64' ] && gh_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/gh/gh-${latest}-$PLATFORM-${gh_arch} ] && echo "gh version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/gh ]] && mkdir -p $BUNDLESDIR/gh

    # Download gh
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest gh version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/cli/cli/releases/download/${latest}/gh_${latest_filename}_${PLATFORM}_${gh_arch}.tar.gz
    tar xzvf gh_${latest_filename}_${PLATFORM}_${gh_arch}.tar.gz

    mv gh_${latest_filename}_${PLATFORM}_${gh_arch}/bin/gh $BUNDLESDIR/gh/gh-${latest}-$PLATFORM-${gh_arch}

    # Set the default version
    rm -f $BUNDLESDIR/gh/default-$PLATFORM-${gh_arch}
    ln -s gh-$latest-$PLATFORM-${gh_arch} $BUNDLESDIR/gh/default-$PLATFORM-${gh_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${gh_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${gh_arch}
    [[ ! -f $BINDIR/$PLATFORM-${gh_arch}/gh ]] && ln -s ../../bundles/gh/default-$PLATFORM-${gh_arch} $BINDIR/$PLATFORM-${gh_arch}/gh

    unset tmpDir
    unset gh_arch
    unset latest
}

function operator-sdk_install {
    echo "Operator SDK install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/operator-framework/operator-sdk/releases/latest | grep 'tag_name' | cut -d\" -f4)
    latest_filename=$(echo $latest | awk -Fv '{ print $2 }')

    # Arch x86_64 used in package names
    operatorsdk_arch=$ARCH
    [ $ARCH = 'x86_64' ] && operatorsdk_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/operator-sdk/operator-sdk-${latest}-$PLATFORM-${operatorsdk_arch} ] && echo "Operator SDK version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/operator-sdk ]] && mkdir -p $BUNDLESDIR/operator-sdk

    # Download Operator SDK
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest Operator SDK version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/operator-framework/operator-sdk/releases/download/${latest}/operator-sdk_${PLATFORM}_${operatorsdk_arch}
    chmod +x operator-sdk_${PLATFORM}_${operatorsdk_arch}

    mv operator-sdk_${PLATFORM}_${operatorsdk_arch} $BUNDLESDIR/operator-sdk/operator-sdk-${latest}-$PLATFORM-${operatorsdk_arch}

    # Set the default version
    rm -f $BUNDLESDIR/operator-sdk/default-$PLATFORM-${operatorsdk_arch}
    ln -s operator-sdk-$latest-$PLATFORM-${operatorsdk_arch} $BUNDLESDIR/operator-sdk/default-$PLATFORM-${operatorsdk_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${operatorsdk_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${operatorsdk_arch}
    [[ ! -f $BINDIR/$PLATFORM-${operatorsdk_arch}/operator-sdk ]] && ln -s ../../bundles/operator-sdk/default-$PLATFORM-${operatorsdk_arch} $BINDIR/$PLATFORM-${operatorsdk_arch}/operator-sdk

    unset tmpDir
    unset operatorsdk_arch
    unset latest
}

function kustomize_install {
    echo "Kustomize install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | grep 'kustomize' | grep 'tag_name' | cut -d\" -f4 | cut -d'/' -f2)

    # Arch x86_64 used in package names
    kustomize_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kustomize_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kustomize/kustomize-${latest}-$PLATFORM-${kustomize_arch} ] && echo "kustomize version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kustomize ]] && mkdir -p $BUNDLESDIR/kustomize

    # Download kustomize
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest kustomize version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${latest}/kustomize_${latest}_${PLATFORM}_${kustomize_arch}.tar.gz
    tar xzvf kustomize_${latest}_${PLATFORM}_${kustomize_arch}.tar.gz

    mv kustomize $BUNDLESDIR/kustomize/kustomize-${latest}-$PLATFORM-${kustomize_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kustomize/default-$PLATFORM-${kustomize_arch}
    ln -s kustomize-$latest-$PLATFORM-${kustomize_arch} $BUNDLESDIR/kustomize/default-$PLATFORM-${kustomize_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kustomize_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kustomize_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kustomize_arch}/kustomize ]] && ln -s ../../bundles/kustomize/default-$PLATFORM-${kustomize_arch} $BINDIR/$PLATFORM-${kustomize_arch}/kustomize

    unset tmpDir
    unset kustomize_arch
    unset latest
}

function kubelogin_install {
    echo "Azure Kubelogin install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/Azure/kubelogin/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 used in package names
    kubelogin_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kubelogin_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubelogin/kubelogin-${latest}-$PLATFORM-${kubelogin_arch} ] && echo "kubelogin version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kubelogin ]] && mkdir -p $BUNDLESDIR/kubelogin

    # Download kubelogin
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest kubelogin version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/Azure/kubelogin/releases/download/${latest}/kubelogin-$PLATFORM-${kubelogin_arch}.zip
    unzip kubelogin-$PLATFORM-${kubelogin_arch}.zip

    chmod 700 bin/${PLATFORM}_${kubelogin_arch}/kubelogin
    mv bin/${PLATFORM}_${kubelogin_arch}/kubelogin $BUNDLESDIR/kubelogin/kubelogin-${latest}-$PLATFORM-${kubelogin_arch}
    

    # Set the default version
    rm -f $BUNDLESDIR/kubelogin/default-$PLATFORM-${kubelogin_arch}
    ln -s kubelogin-$latest-$PLATFORM-${kubelogin_arch} $BUNDLESDIR/kubelogin/default-$PLATFORM-${kubelogin_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubelogin_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubelogin_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubelogin_arch}/kubelogin ]] && ln -s ../../bundles/kubelogin/default-$PLATFORM-${kubelogin_arch} $BINDIR/$PLATFORM-${kubelogin_arch}/kubelogin

    unset tmpDir
    unset kubelogin_arch
    unset latest
}

function helm_install {
    echo "Helm install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 used in package names
    helm_arch=$ARCH
    [ $ARCH = 'x86_64' ] && helm_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/helm/helm-${latest}-$PLATFORM-${helm_arch} ] && echo "Helm version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/helm ]] && mkdir -p $BUNDLESDIR/helm

    # Download Helm
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest helm version: ${latest}"
    wget --quiet --continue --show-progress https://get.helm.sh/helm-${latest}-$PLATFORM-${helm_arch}.tar.gz
    tar xzvf helm-${latest}-$PLATFORM-${helm_arch}.tar.gz

    mv $PLATFORM-${helm_arch}/helm $BUNDLESDIR/helm/helm-${latest}-$PLATFORM-${helm_arch}
    
    # Set the default version
    rm -f $BUNDLESDIR/helm/default-$PLATFORM-${helm_arch}
    ln -s helm-$latest-$PLATFORM-${helm_arch} $BUNDLESDIR/helm/default-$PLATFORM-${helm_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${helm_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${helm_arch}
    [[ ! -f $BINDIR/$PLATFORM-${helm_arch}/helm ]] && ln -s ../../bundles/helm/default-$PLATFORM-${helm_arch} $BINDIR/$PLATFORM-${helm_arch}/helm

    unset tmpDir
    unset kubelogin_arch
    unset latest
}

function k9s_install {
    echo "K9s install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 used in package names
    k9s_arch=$ARCH
    [ $ARCH = 'x86_64' ] && k9s_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/k9s/k9s-${latest}-$PLATFORM-${k9s_arch} ] && echo "k9s version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/k9s ]] && mkdir -p $BUNDLESDIR/k9s

    # Download k9s
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest k9s version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/derailed/k9s/releases/download/${latest}/k9s_${PLATFORM}_${k9s_arch}.tar.gz
    tar xzvf k9s_${PLATFORM}_${k9s_arch}.tar.gz

    mv k9s $BUNDLESDIR/k9s/k9s-${latest}-$PLATFORM-${k9s_arch}
    
    # Set the default version
    rm -f $BUNDLESDIR/k9s/default-$PLATFORM-${k9s_arch}
    ln -s k9s-$latest-$PLATFORM-${k9s_arch} $BUNDLESDIR/k9s/default-$PLATFORM-${k9s_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${k9s_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${k9s_arch}
    [[ ! -f $BINDIR/$PLATFORM-${k9s_arch}/k9s ]] && ln -s ../../bundles/k9s/default-$PLATFORM-${k9s_arch} $BINDIR/$PLATFORM-${k9s_arch}/k9s

    unset tmpDir
    unset k9s_arch
    unset latest
}

function redis-cli_install {
    echo "redis-cli bundle generation"

    # Recreate tmp working dir
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd $tmpDir

    # Clone git repo and choose the latest released version
    git clone https://github.com/redis/redis.git
    cd redis
    git fetch --tags
    tag=$(git tag -l --sort=-v:refname | grep -oP '^[0-9\.]+$' | head -n 1)

    # Arch x86_64 is replaced by amd64
    rediscli_arch=$ARCH
    [ $ARCH = 'x86_64' ] && rediscli_arch='amd64'

    # Check if already installed
    [ -d $BUNDLESDIR/redis-cli/redis-cli-$tag-$PLATFORM-$rediscli_arch ] && echo "redis-cli version ${tag} already installed!" && rm -rf $tmpDir && unset tmpDir && return
    [[ ! -d $BUNDLESDIR/redis-cli ]] && mkdir -p $BUNDLESDIR/redis-cli

    # Configure, build and install
    git checkout $tag -b version-to-install
    make redis-cli

    mv src/redis-cli $BUNDLESDIR/redis-cli/redis-cli-${tag}-$PLATFORM-${rediscli_arch}

    # Set the default version
    rm -f $BUNDLESDIR/redis-cli/default-$PLATFORM-$rediscli_arch
    ln -s redis-cli-$tag-$PLATFORM-$rediscli_arch $BUNDLESDIR/redis-cli/default-$PLATFORM-$rediscli_arch

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${rediscli_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${rediscli_arch}
    [[ ! -f $BINDIR/$PLATFORM-${rediscli_arch}/redis-cli ]] && ln -s ../../bundles/redis-cli/default-$PLATFORM-${rediscli_arch} $BINDIR/$PLATFORM-${rediscli_arch}/redis-cli

    unset rediscli_arch
    unset tmpDir
}

function velero_install {
    echo "Velero install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 used in package names
    velero_arch=$ARCH
    [ $ARCH = 'x86_64' ] && velero_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/velero/velero-${latest}-$PLATFORM-${velero_arch} ] && echo "velero version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/velero ]] && mkdir -p $BUNDLESDIR/velero

    # Download velero
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest velero version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/vmware-tanzu/velero/releases/download/${latest}/velero-${latest}-${PLATFORM}-${velero_arch}.tar.gz
    tar xzvf velero-${latest}-${PLATFORM}-${velero_arch}.tar.gz

    mv velero-${latest}-$PLATFORM-${velero_arch}/velero $BUNDLESDIR/velero/velero-${latest}-$PLATFORM-${velero_arch}
    
    # Set the default version
    rm -f $BUNDLESDIR/velero/default-$PLATFORM-${velero_arch}
    ln -s velero-$latest-$PLATFORM-${velero_arch} $BUNDLESDIR/velero/default-$PLATFORM-${velero_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${velero_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${velero_arch}
    [[ ! -f $BINDIR/$PLATFORM-${velero_arch}/velero ]] && ln -s ../../bundles/velero/default-$PLATFORM-${velero_arch} $BINDIR/$PLATFORM-${velero_arch}/velero

    unset tmpDir
    unset velero_arch
    unset latest
}

function krew_install {
    echo "krew install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/kubernetes-sigs/krew/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 used in package names
    krew_arch=$ARCH
    [ $ARCH = 'x86_64' ] && krew_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/krew/krew-${latest}-$PLATFORM-${krew_arch} ] && echo "krew version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/krew ]] && mkdir -p $BUNDLESDIR/krew

    # Download krew
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest krew version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/kubernetes-sigs/krew/releases/download/${latest}/krew-${PLATFORM}_${krew_arch}.tar.gz
    tar xzvf krew-${PLATFORM}_${krew_arch}.tar.gz

    mv krew-${PLATFORM}_${krew_arch} $BUNDLESDIR/krew/krew-${latest}-$PLATFORM-${krew_arch}
    
    # Set the default version
    rm -f $BUNDLESDIR/krew/default-$PLATFORM-${krew_arch}
    ln -s krew-$latest-$PLATFORM-${krew_arch} $BUNDLESDIR/krew/default-$PLATFORM-${krew_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${krew_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${krew_arch}
    [[ ! -f $BINDIR/$PLATFORM-${krew_arch}/krew ]] && ln -s ../../bundles/krew/default-$PLATFORM-${krew_arch} $BINDIR/$PLATFORM-${krew_arch}/krew

    unset tmpDir
    unset krew_arch
    unset latest
}

function krew-krew_install {
    krew install krew
}

function krew-profefe_install {
    kubectl krew install profefe
}

function krew-neat_install {
    kubectl krew install neat
}

function krew-rabbitmq_install {
    kubectl krew install rabbitmq
}

function kubebuilder_install {
    echo "kubebuilder install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/kubernetes-sigs/kubebuilder/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 used in package names
    kubebuilder_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kubebuilder_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubebuilder/kubebuilder-${latest}-$PLATFORM-${kubebuilder_arch} ] && echo "kubebuilder version ${latest} already installed!" && return
    [[ ! -d $BUNDLESDIR/kubebuilder ]] && mkdir -p $BUNDLESDIR/kubebuilder

    # Download kubebuilder
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && return)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && return)
    cd ${tmpDir}
    echo "Downloading latest kubebuilder version: ${latest}"
    wget --quiet --continue --show-progress https://github.com/kubernetes-sigs/kubebuilder/releases/download/${latest}/kubebuilder_${PLATFORM}_${kubebuilder_arch}

    mv kubebuilder_${PLATFORM}_${kubebuilder_arch} $BUNDLESDIR/kubebuilder/kubebuilder-${latest}-$PLATFORM-${kubebuilder_arch}
    chmod u+x $BUNDLESDIR/kubebuilder/kubebuilder-${latest}-$PLATFORM-${kubebuilder_arch}
    
    # Set the default version
    rm -f $BUNDLESDIR/kubebuilder/default-$PLATFORM-${kubebuilder_arch}
    ln -s kubebuilder-$latest-$PLATFORM-${kubebuilder_arch} $BUNDLESDIR/kubebuilder/default-$PLATFORM-${kubebuilder_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubebuilder_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubebuilder_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubebuilder_arch}/kubebuilder ]] && ln -s ../../bundles/kubebuilder/default-$PLATFORM-${kubebuilder_arch} $BINDIR/$PLATFORM-${kubebuilder_arch}/kubebuilder

    unset tmpDir
    unset kubebuilder_arch
    unset latest
}

# Determine OS platform
PLATFORM=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$PLATFORM" = "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" = "" ] && export DISTRO=$PLATFORM
ARCH=$(arch)

echo "OS platform detected: $PLATFORM $DISTRO ($ARCH)"

[[ "$@" = "" ]] && usage && exit 0
[ "$#" -ne 1 ] && echo "Error: Wrong number of arguments" && usage && exit 1

case "$1" in
    "git")
        git_install
        ;;
    "maven")
        maven_install
        ;;
    "ant")
        ant_install
        ;;
    "docker-compose")
        docker_compose_install
        ;;
    "minikube")
        minikube_install
        ;;
    "kubectl")
        kubectl_install
        ;;
    "kubectx")
        kubectx_install
        ;;
    "kubens")
        kubens_install
        ;;
    "k3sup")
        k3sup_install
        ;;
    "k3d")
        k3d_install
        ;;
    "kind")
        kind_install
        ;;
    "knative")
        knative_install
        ;;
    "terraform")
        terraform_install
        ;;
    "yq")
        yq_install
        ;;
    "conftest")
        conftest_install
        ;;
    "kubeconform")
        kubeconform_install
        ;;
    "oc")
        oc_install
        ;;
    "opm")
        opm_install
        ;;
    "gh")
        gh_install
        ;;
    "operator-sdk")
        operator-sdk_install
        ;;
    "kustomize")
        kustomize_install
        ;;
    "kubelogin")
        kubelogin_install
        ;;
    "helm")
        helm_install
        ;;
    "k9s")
        k9s_install
        ;;
    "redis-cli")
        redis-cli_install
        ;;
    "velero")
        velero_install
        ;;
    "krew")
        krew_install
        ;;
    "krew-krew")
        krew-krew_install
        ;;
    "krew-profefe")
        krew-profefe_install
        ;;
    "krew-neat")
        krew-neat_install
        ;;
    "krew-rabbitmq")
        krew-rabbitmq_install
        ;;
    "kubebuilder")
        kubebuilder_install
        ;;
    "all")
        git_install
        maven_install
        ant_install
        docker_compose_install
        minikube_install
        kubectl_install
        kubectx_install
        kubens_install
        k3sup_install
        k3d_install
        kind_install
        knative_install
        terraform_install
        yq_install
        conftest_install
        kubeconform_install
        oc_install
        opm_install
        gh_install
        operator-sdk_install
        kustomize_install
        kubelogin_install
        helm_install
        k9s_install
        redis-cli_install
        velero_install
        krew_install
        krew-krew_install
        krew-profefe_install
        krew-neat_install
        krew-rabbitmq_install
        kubebuilder_install
        ;;
    *)
        echo "Error: Bundle or package name invalid" && usage && exit 1
        ;;
esac

exit 0
