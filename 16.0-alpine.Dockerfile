FROM surnet/alpine-wkhtmltopdf:3.16.0-0.12.6-small as wkhtmltopdf

FROM python:3.10-alpine AS builder
RUN set -x; \
        apk add --no-cache python3-dev libffi-dev gcc musl-dev make postgresql-dev openldap-dev cyrus-sasl-dev jpeg-dev zlib-dev libsass-dev g++ &&\
        pip install wheel &&\
        echo 'INPUT ( libldap.so )' > /usr/lib/libldap_r.so &&\
        pip wheel --wheel-dir=/svc/wheels -r https://raw.githubusercontent.com/odoo/odoo/master/requirements.txt &&\
        pip wheel --wheel-dir=/svc/wheels phonenumbers simplejson openupgradelib PyYAML


FROM python:3.10-alpine AS final
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PGDATABASE=odoo

RUN set -x; \
        apk add --no-cache \
            bash \
           	fontconfig \
            freetype \
            git \
            libjpeg-turbo \
            libsass \
            libstdc++ \
            libx11 \
           	libxrender \
            postgresql-client

# Copy wkhtmltopdf files from docker-wkhtmltopdf image
COPY --from=wkhtmltopdf /bin/wkhtmltopdf /bin/wkhtmltopdf

COPY --from=builder /svc /svc
RUN pip3 install --no-index --find-links=/svc/wheels -r https://raw.githubusercontent.com/odoo/odoo/master/requirements.txt &&\
        pip3 install --no-index --find-links=/svc/wheels phonenumbers simplejson openupgradelib PyYAML

# Add Git Known Hosts
COPY ./ssh_known_git_hosts /root/.ssh/known_hosts

# Install Odoo and remove not French translations and .git directory to limit amount of data used by container
RUN set -x; \
        adduser -h /opt/odoo -D odoo &&\
        /bin/bash -c "mkdir -p /opt/odoo/{etc,odoo,additional_addons,private_addons,data,private}" &&\
        git clone -b 16.0 --depth 1 https://github.com/OCA/OCB.git /opt/odoo/odoo &&\
        rm -rf /opt/odoo/odoo/.git &&\
        find /opt/odoo/odoo/addons/*/i18n/ /opt/odoo/odoo/odoo/addons/base/i18n/ -type f -not -name 'fr.po' -delete &&\
        chown -R odoo:odoo /opt/odoo

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /opt/odoo/etc/odoo.conf
RUN chown odoo:odoo /opt/odoo/etc/odoo.conf

# Mount /opt/odoo/data to allow restoring filestore
VOLUME ["/opt/odoo/data/"]

# Expose Odoo services
EXPOSE 8069

# Set default user when running the container
USER odoo

# Start
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]

# Metadata
LABEL org.label-schema.schema-version="16.0" \
      org.label-schema.vendor=LeFilament \
      org.label-schema.license=Apache-2.0 \
      org.label-schema.vcs-url="https://sources.le-filament.com/lefilament/odoo_docker"
