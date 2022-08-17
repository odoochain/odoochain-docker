FROM python:3.10-slim-bullseye AS builder
RUN set -x; \
        apt-get update &&\
        apt-get install -y --no-install-recommends build-essential libldap2-dev libpq-dev libsasl2-dev &&\
        pip install wheel &&\
        pip wheel --wheel-dir=/svc/wheels -r https://raw.githubusercontent.com/odoo/odoo/master/requirements.txt &&\
        pip wheel --wheel-dir=/svc/wheels phonenumbers simplejson openupgradelib PyYAML


FROM python:3.10-slim-bullseye AS final
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PGDATABASE=odoo

RUN set -x; \
        apt-get update &&\
        apt-get install -y --no-install-recommends \
            curl \
            git \
            gnupg \
            openssh-client \
            xmlsec1 &&\
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' >> /etc/apt/sources.list.d/postgresql.list &&\
        curl -SL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&\
        curl -o wkhtmltox.deb -SL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb &&\
        echo 'cecbf5a6abbd68d324a7cd6c51ec843d71e98951 wkhtmltox.deb' | sha1sum -c - &&\
        apt-get update &&\
        apt-get install -y --no-install-recommends ./wkhtmltox.deb &&\
        apt-get install -y --no-install-recommends postgresql-client &&\
        apt-get -y autoremove &&\
        rm -rf /var/lib/apt/lists/* wkhtmltox.deb

COPY --from=builder /svc /svc
RUN pip3 install --no-index --find-links=/svc/wheels -r https://raw.githubusercontent.com/odoo/odoo/master/requirements.txt &&\
        pip3 install --no-index --find-links=/svc/wheels phonenumbers simplejson openupgradelib PyYAML

# Add Git Known Hosts
COPY ./ssh_known_git_hosts /root/.ssh/known_hosts

# Install Odoo and remove not French translations and .git directory to limit amount of data used by container
RUN set -x; \
        useradd --create-home --home-dir /opt/odoo --no-log-init odoo &&\
        /bin/bash -c "mkdir -p /opt/odoo/{etc,odoo,additional_addons,private_addons,data,private}" &&\
        # git clone -b 16.0 --depth 1 https://github.com/OCA/OCB.git /opt/odoo/odoo &&\
        git clone -b master --depth 1 https://github.com/odoo/odoo.git /opt/odoo/odoo &&\
        rm -rf /opt/odoo/odoo/.git &&\
        find /opt/odoo/odoo/addons/*/i18n/ /opt/odoo/odoo/odoo/addons/base/i18n/ -type f -not -name 'fr.po' -delete &&\
        chown -R odoo:odoo /opt/odoo

# Install Odoo OCA default dependencies - These modules do not exist for now
#RUN set -x; \
#        mkdir -p /tmp/oca-repos/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/account-financial-reporting.git /tmp/oca-repos/account-financial-reporting &&\
#        mv /tmp/oca-repos/account-financial-reporting/account_tax_balance /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/account-financial-tools.git /tmp/oca-repos/account-financial-tools &&\
#        mv /tmp/oca-repos/account-financial-tools/account_lock_date_update \
#           /tmp/oca-repos/account-financial-tools/account_move_name_sequence \
#           /opt/odoo/additional_addons/ &&\
#        # Until migrated to OCA (https://github.com/OCA/account-financial-tools/pull/1304)
#        git clone -b 16.0-add-partner_account_reconciliable --depth 1 https://github.com/lefilament/account-financial-tools.git /tmp/oca-repos/account-financial-tools-lf &&\
#        mv /tmp/oca-repos/account-financial-tools-lf/partner_account_reconciliable /opt/odoo/additional_addons/ &&\
#        # Until migrated to OCA (https://github.com/OCA/account-invoicing/pull/897)
#        git clone -b 16.0-mig-sale-timesheet-invoice-description --depth 1 https://github.com/akretion/account-invoicing.git /tmp/oca-repos/account-invoicing-ak &&\
#        mv /tmp/oca-repos/account-invoicing-ak/sale_timesheet_invoice_description \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/account-reconcile.git /tmp/oca-repos/account-reconcile &&\
#        mv /tmp/oca-repos/account-reconcile/account_reconciliation_widget \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/bank-statement-import.git /tmp/oca-repos/bank-statement-import &&\
#        mv /tmp/oca-repos/bank-statement-import/account_statement_import \
#           /tmp/oca-repos/bank-statement-import/account_statement_import_ofx \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/crm.git /tmp/oca-repos/crm &&\
#        mv /tmp/oca-repos/crm/crm_stage_probability /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/partner-contact.git /tmp/oca-repos/partner-contact &&\
#        mv /tmp/oca-repos/partner-contact/partner_disable_gravatar \
#           /tmp/oca-repos/partner-contact/partner_firstname \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/project.git /tmp/oca-repos/project &&\
#        mv /tmp/oca-repos/project/project_category \
#           /tmp/oca-repos/project/project_status \
#           /tmp/oca-repos/project/project_task_default_stage \
#           /tmp/oca-repos/project/project_template \
#           /tmp/oca-repos/project/project_timeline \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/server-auth.git /tmp/oca-repos/server-auth &&\
#        mv /tmp/oca-repos/server-auth/password_security \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/server-brand.git /tmp/oca-repos/server-brand &&\
#        mv /tmp/oca-repos/server-brand/disable_odoo_online \
#           /tmp/oca-repos/server-brand/remove_odoo_enterprise \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/server-tools.git /tmp/oca-repos/server-tools &&\
#        mv /tmp/oca-repos/server-tools/base_search_fuzzy \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/server-ux.git /tmp/oca-repos/server-ux &&\
#        mv /tmp/oca-repos/server-ux/base_technical_features \
#           /tmp/oca-repos/server-ux/date_range \
#           /tmp/oca-repos/server-ux/mass_editing \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/social.git /tmp/oca-repos/social &&\
#        mv /tmp/oca-repos/social/base_search_mail_content \
#           /tmp/oca-repos/social/mail_debrand \
#           /opt/odoo/additional_addons/ &&\
#        git clone -b 16.0 --depth 1 https://github.com/OCA/web.git /tmp/oca-repos/web &&\
#        mv /tmp/oca-repos/web/web_environment_ribbon \
#           /tmp/oca-repos/web/web_responsive \
#           /tmp/oca-repos/web/web_no_bubble \
#           /tmp/oca-repos/web/web_timeline \
#           /opt/odoo/additional_addons/ &&\
#        rm -rf /tmp/oca-repos/ &&\
#        find /opt/odoo/additional_addons/*/i18n/ -type f -not -name 'fr.po' -delete &&\
#        # Install Le Filament default dependency
#        git clone -b 16.0 --depth 1 https://sources.le-filament.com/lefilament/remove_login_links.git /opt/odoo/private_addons/remove_login_links &&\
#        chown -R odoo:odoo /opt/odoo

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