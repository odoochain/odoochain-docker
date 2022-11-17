FROM surnet/alpine-wkhtmltopdf:3.16.0-0.12.6-small as wkhtmltopdf


FROM alpine as build

# Initial setup of new root.
RUN apk update \
    && mkdir --parents \
        /newroot/etc \
        /newroot/bin \
        /newroot/usr/bin \
    && cp -a --parents \
        /bin/busybox \
        /lib/ld-musl* \
        /newroot/ \
    && /bin/busybox --install -s /newroot/bin/ \
    && /bin/busybox --install -s /newroot/usr/bin/ \
    && echo 'root:x:0:0:::' > /newroot/etc/passwd \
    && echo 'root:x:0:' > /newroot/etc/group

# Add depedencies
RUN apk add --no-cache \
        file \
        freetype-dev \
        g++ \
        gcc \
        git \
        jpeg-dev \
        libev-dev \
        libffi-dev \
        libx11-dev \
        libxrender-dev \
        fontconfig-dev \
        make \
        musl-dev \
        openldap-dev \
        postgresql-dev \
        py3-pip \
        python3 \
        python3-dev \
        zlib-dev

# Add Odoo.
RUN git clone -b 16.0 --depth 1 https://github.com/OCA/OCB.git /newroot/opt/odoo/odoo \
    && rm -rf /newroot/opt/odoo/odoo/.git \
    && find /newroot/opt/odoo/odoo/addons/*/i18n/ /newroot/opt/odoo/odoo/odoo/addons/base/i18n/ -type f -not -name 'fr.po' -delete

## Add Git known hosts.
COPY ./ssh_known_git_hosts /root/.ssh/known_hosts

## Install Odoo OCA and Le Filament default dependencies.
RUN mkdir -p \
        /tmp/oca-repos/ \
        /newroot/opt/odoo/additional_addons \
        /newroot/opt/odoo/private_addons \
    && git clone -b 16.0 --depth 1 \
        https://github.com/OCA/account-financial-reporting.git \
        /tmp/oca-repos/account-financial-reporting \
    && mv /tmp/oca-repos/account-financial-reporting/account_tax_balance \
        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/account-financial-tools.git \
#        /tmp/oca-repos/account-financial-tools \
#    && mv /tmp/oca-repos/account-financial-tools/account_lock_date_update \
#        /tmp/oca-repos/account-financial-tools/account_move_name_sequence \
#        /tmp/oca-repos/account-financial-tools/account_reconcile_show_boolean \
#        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/account-invoicing.git \
#        /tmp/oca-repos/account-invoicing \
#    && mv /tmp/oca-repos/account-invoicing/sale_timesheet_invoice_description \
#        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/account-reconcile.git \
#        /tmp/oca-repos/account-reconcile \
#    && mv /tmp/oca-repos/account-reconcile/account_reconciliation_widget \
#        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/bank-statement-import.git \
#        /tmp/oca-repos/bank-statement-import \
#    && mv /tmp/oca-repos/bank-statement-import/account_statement_import \
#        /tmp/oca-repos/bank-statement-import/account_statement_import_ofx \
#        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/crm.git \
#        /tmp/oca-repos/crm \
#    && mv /tmp/oca-repos/crm/crm_stage_probability \
#        /newroot/opt/odoo/additional_addons/ \
    && git clone -b 16.0 --depth 1 \
        https://github.com/OCA/partner-contact.git \
        /tmp/oca-repos/partner-contact \
    && mv /tmp/oca-repos/partner-contact/partner_disable_gravatar \
        /tmp/oca-repos/partner-contact/partner_firstname \
        /newroot/opt/odoo/additional_addons/ \
    && git clone -b 16.0 --depth 1 \
        https://github.com/OCA/project.git \
        /tmp/oca-repos/project \
#    && mv /tmp/oca-repos/project/project_category \
#        /tmp/oca-repos/project/project_status \
     && mv /tmp/oca-repos/project/project_task_default_stage \
        /tmp/oca-repos/project/project_template \
#        /tmp/oca-repos/project/project_timeline \
        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/server-auth.git \
#        /tmp/oca-repos/server-auth \
#    && mv /tmp/oca-repos/server-auth/password_security \
#        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/server-brand.git \
#        /tmp/oca-repos/server-brand \
#    && mv /tmp/oca-repos/server-brand/disable_odoo_online \
#        /tmp/oca-repos/server-brand/remove_odoo_enterprise \
#        /newroot/opt/odoo/additional_addons/ \
    && git clone -b 16.0 --depth 1 \
        https://github.com/OCA/server-tools.git \
        /tmp/oca-repos/server-tools \
#    && mv /tmp/oca-repos/server-tools/base_search_fuzzy \
    && mv /tmp/oca-repos/server-tools/module_change_auto_install \
        /newroot/opt/odoo/additional_addons/ \
    && git clone -b 16.0 --depth 1 \
        https://github.com/OCA/server-ux.git \
        /tmp/oca-repos/server-ux \
    && mv /tmp/oca-repos/server-ux/base_technical_features \
        /tmp/oca-repos/server-ux/date_range \
#        /tmp/oca-repos/server-ux/mass_editing \
        /newroot/opt/odoo/additional_addons/ \
#    && git clone -b 16.0 --depth 1 \
#        https://github.com/OCA/social.git \
#        /tmp/oca-repos/social \
#    && mv /tmp/oca-repos/social/base_search_mail_content \
#        /tmp/oca-repos/social/mail_debrand \
#        /tmp/oca-repos/social/mail_tracking \
#        /newroot/opt/odoo/additional_addons/ \
    && git clone -b 16.0 --depth 1 \
        https://github.com/OCA/web.git \
        /tmp/oca-repos/web \
    && mv /tmp/oca-repos/web/web_environment_ribbon \
#        /tmp/oca-repos/web/web_responsive \
#        /tmp/oca-repos/web/web_no_bubble \
#        /tmp/oca-repos/web/web_timeline \
        /newroot/opt/odoo/additional_addons/ \
    && rm -rf /tmp/oca-repos/ \
    && find /newroot/opt/odoo/additional_addons/*/i18n/ -type f -not -name 'fr.po' -delete
#    && git clone -b 16.0 --depth 1 \
#        https://sources.le-filament.com/lefilament/remove_login_links.git \
#        /newroot/opt/odoo/private_addons/remove_login_links \
#    && git clone -b 16.0 --depth 1 \
#        https://sources.le-filament.com/lefilament/lefilament_release_agent.git \
#        /newroot/opt/odoo/private_addons/lefilament_release_agent

# Fix a ldap library bug.
RUN echo -n "INPUT ( libldap.so )" > /usr/lib/libldap_r.so

# Install Python requirements.
RUN pip install --requirement /newroot/opt/odoo/odoo/requirements.txt

# Only copy libraries of needed binaries to new root.
RUN ls \
        /lib/libz.so* \
        /usr/bin/python3* \
        /usr/lib/libexpat.so* \
        /usr/lib/libfontconfig.so* \
        /usr/lib/libfreetype.so* \
        /usr/lib/libjpeg.so* \
        /usr/lib/libpq.so* \
        /usr/lib/libpython3.so* \
        /usr/lib/python3.10/lib-dynload/*.so \
        /usr/lib/python3.10/site-packages/*.so \
        /usr/lib/libX11.so* \
        /usr/lib/libXrender.so* \
        > to_copy \
    && xargs -a to_copy -I R ldd R \
    | tr -s '[:blank:]' '\n' \
    | grep '^/' \
    | sed 's/://' \
    | sort -u \
    | xargs cp -aL --parents -t /newroot/ \
    && xargs -a to_copy cp -a --parents -t /newroot/

# Copy Python libraries.
RUN cp -a --parents \
        /usr/lib/python3.10/ \
        /newroot

COPY --from=wkhtmltopdf /bin/wkhtmltopdf /newroot/bin/wkhtmltopdf
COPY ./entrypoint-scratch.sh /newroot/entrypoint.sh

# Add odoo user.
RUN echo 'odoo:x:1:1:::' >> /newroot/etc/passwd \
    && echo 'odoo:x:1:' >> /newroot/etc/group \
    && chown -R 1:1 /newroot/opt/odoo/ \
    && chmod 555 /newroot/entrypoint.sh \
    && mkdir /newroot/tmp \
    && chmod 1777 /newroot/tmp


# Final image.
FROM scratch

COPY --from=build /newroot /

# Mount /opt/odoo/data to allow restoring filestore.
VOLUME ["/opt/odoo/data/"]

# Expose Odoo services.
EXPOSE 8069

# Set default user when running the container.
USER odoo

# Start
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]

# Metadata
LABEL org.label-schema.schema-version="16.0" \
      org.label-schema.vendor=LeFilament \
      org.label-schema.license=Apache-2.0 \
      org.label-schema.vcs-url="https://sources.le-filament.com/lefilament/odoo_docker"
