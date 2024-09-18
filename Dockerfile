FROM python:3.10-slim as build-image

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV APPLICATIONDIR=/opt/app
ENV VIRTUAL_ENV=/opt/venv

ENV SSL_CERT_DIR=/etc/ssl/certs
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    python3-dev \
    python3-venv \
    python3-pip \    
    build-essential && \    
    rm -fr /var/lib/apt/lists && \
    apt-get clean && \
    apt-get autoremove && \
    apt-get autoclean -y

COPY pip.conf /etc/pip.conf

RUN python -m venv ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

WORKDIR ${APPLICATIONDIR}

COPY requirements.txt .
RUN pip install --upgrade pip && pip install pip-system-certs
RUN pip install --no-cache-dir wheel
RUN pip install --no-cache-dir -r requirements.txt

# Build runner image
FROM python:3.10-slim as runner-image

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV LOCALE=pt_BR.UTF-8
ENV LANG=${LOCALE}
ENV LANGUAGE=${LOCALE}
ENV LC_CTYPE=${LOCALE}
ENV LC_NUMERIC=${LOCALE}
ENV LC_TIME=${LOCALE}
ENV LC_COLLATE=${LOCALE}
ENV LC_MONETARY=${LOCALE}
ENV LC_MESSAGES=${LOCALE}
ENV LC_PAPER=${LOCALE}
ENV LC_NAME=${LOCALE}
ENV LC_ADDRESS=${LOCALE}
ENV LC_TELEPHONE=${LOCALE}
ENV LC_MEASUREMENT=${LOCALE}
ENV LC_IDENTIFICATION=${LOCALE}
ENV LC_ALL=C

ENV APPLICATIONDIR=/opt/app
ENV VIRTUAL_ENV=/opt/venv

ENV SSL_CERT_DIR=/etc/ssl/certs
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-distutils \    
    locales && \
    rm -fr /var/lib/apt/lists && \
    apt-get clean && \
    apt-get autoremove && \
    apt-get autoclean -y

WORKDIR ${APPLICATIONDIR}

# FIX LOCALE
RUN sed -i -e 's/# pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=${LOCALE}

# PYTHON ENVIRONMENT
COPY pip.conf /etc/pip.conf
COPY --from=build-image ${VIRTUAL_ENV} ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

RUN pip install --upgrade pip && pip install pip-system-certs

COPY . ${APPLICATIONDIR}

CMD ["python", "src/manage.py", "runserver 0.0.0.0:8000", "--nothreading",  "--noreload"]
