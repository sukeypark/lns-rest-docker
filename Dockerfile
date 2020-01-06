FROM node as builder

COPY github_key .
RUN chmod 600 github_key && \
    eval $(ssh-agent) && \
    ssh-add github_key && \
    ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts && \
    git clone git@github.com:Data-Alliance/lora_rest.git /opt/lns-rest

FROM hspark3480/test:lns-rest-base

COPY --from=builder /opt/lns-rest /home/ubuntu/lns_rest
RUN addgroup -g 1111 ubuntu && \
    adduser -S -u 1111 -g ubuntu ubuntu && \
    mkdir /home/ubuntu/lns_rest/log && \
    chmod -R 777 /home/ubuntu/lns_rest
USER ubuntu
WORKDIR /home/ubuntu/lns_rest
EXPOSE 8000
CMD python manage.py collectstatic --settings=rest_api.settings.deploy --noinput\
    && uwsgi --http :8000 --ini /home/ubuntu/lns_rest/docker_deploy.ini