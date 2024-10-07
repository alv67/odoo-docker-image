# Use a Python base image
FROM python:3.11-slim

# Setup environment
ENV ODOO_VERSION=18.0 \
    ODOO_USER=odoo \
    ODOO_HOME=/opt/odoo \
    ODOO_RC=/etc/odoo/odoo.conf \
    WKHTMLTOX_VERSION=0.12.6.1-3

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
    git \
    wget \
    build-essential \
    python3-dev \
    python3-pip \
    python3-babel \
    libldap2-dev \
    libsasl2-dev \
    libpq-dev
# Dependencies for wkhtmltopdf
RUN apt-get install -y \
    libxrender1 \
    libxext6 \
    fontconfig \  
    libfontconfig1 \
    xfonts-75dpi \
    xfonts-base \
    && apt-get clean

# Create user
RUN useradd --system --home=${ODOO_HOME} ${ODOO_USER}

# Set working directory
WORKDIR ${ODOO_HOME}

# Install wkhtmltopdf  by choosing the right architecture
RUN ARCH="$(uname -m)" && \
if [ "$ARCH" = "x86_64" ]; then \
echo "Downloading wkhtmltopdf for amd64..." && \
wget https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOX_VERSION}/wkhtmltox_${WKHTMLTOX_VERSION}.bookworm_amd64.deb; \
elif [ "$ARCH" = "aarch64" ]; then \
echo "Downloading wkhtmltopdf for arm64..." && \
wget https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOX_VERSION}/wkhtmltox_${WKHTMLTOX_VERSION}.bookworm_arm64.deb; \
else \
echo "Unsupported architecture: $ARCH" && exit 1; \
fi && \
dpkg -i wkhtmltox_${WKHTMLTOX_VERSION}.bookworm_*.deb && \
apt-get -f install -y && \
rm wkhtmltox_${WKHTMLTOX_VERSION}.bookworm_*.deb

# Clone Odoo sources from official repository
RUN git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo.git ${ODOO_HOME}

# Install pip and all dependencies
RUN pip3 install -r requirements.txt

# Create Odoo configuration
RUN mkdir -p /etc/odoo && \
    echo "[options]" > ${ODOO_RC} && \
    echo "admin_passwd = admin" >> ${ODOO_RC} && \
    echo "db_host = db" >> ${ODOO_RC} && \
    echo "db_port = 5432" >> ${ODOO_RC} && \
    echo "db_user = odoo" >> ${ODOO_RC} && \
    echo "db_password = odoo" >> ${ODOO_RC} && \
    echo "addons_path = /opt/odoo/addons" >> ${ODOO_RC}
    
# Expose Odoo ports
EXPOSE 8069

# Command to start Odoo
CMD ["python", "odoo-bin", "-d", "mydb", "-c", "/etc/odoo/odoo.conf" ]
