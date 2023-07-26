FROM mcr.microsoft.com/powershell:ubi-9

RUN dnf upgrade --refresh -y && \
    dnf install git -y

ENV HOME=/home/user
ENV PROJECTS=/projects/

RUN mkdir /projects ${HOME} && \
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

WORKDIR /projects

ADD scripts/* ${PROJECTS}
ADD entrypoint.sh /

RUN curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" | tar -C /bin -xvzf - govc
RUN git clone https://github.com/lenovo/powershell-redfish-lenovo

RUN export POWERSHELL_TELEMETRY_OPTOUT=1 && \
	pwsh -NoLogo -NoProfile -Command " \
          \$ErrorActionPreference = 'Stop' ; \
          \$ProgressPreference = 'SilentlyContinue' ; \
          Set-PSRepository -Name PSGallery -InstallationPolicy Trusted ; \
          Install-Module -Force -Scope AllUsers PSSlack"

RUN for f in "${HOME}" "/etc/hosts"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

ENTRYPOINT ["/entrypoint.sh"]
