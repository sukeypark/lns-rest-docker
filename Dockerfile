FROM node as builder

COPY github_key .
RUN chmod 600 github_key && \
    eval $(ssh-agent) && \
    ssh-add github_key && \
    ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts && \
    git clone git@github.com:Data-Alliance/lora_rest.git /opt/lns-rest

FROM python:alpine

ARG UID=1000
ARG GID=1000
ARG USER_NAME=ubuntu
ARG GROUP_NAME=ubuntu

ENV REST_PORT 8000

COPY --from=builder /opt/lns-rest /home/ubuntu/lns_rest
RUN apk add --update \
    build-base libffi-dev \
  && pip install -r /home/ubuntu/lns_rest/requirements.txt \
  && pip install uwsgi \
  && rm -rf /var/cache/apk/* \
  && addgroup -g $GID $GROUP_NAME \ 
  && adduser -S -G $GROUP_NAME -u $UID -G $USER_NAME $GROUP_NAME \
  && mkdir /home/ubuntu/lns_rest/log \
  && chmod -R 777 /home/ubuntu/lns_rest
USER ubuntu
WORKDIR /home/ubuntu/lns_rest
EXPOSE $REST_PORT
CMD python manage.py collectstatic --settings=rest_api.settings.deploy --noinput\
    && uwsgi --http :$REST_PORT --ini /home/ubuntu/lns_rest/docker_deploy.ini