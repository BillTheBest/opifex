FROM node:6-slim

MAINTAINER wot.io devs <dev@wot.io>

COPY dist/node_modules/opifex /usr/local/lib/node_modules/opifex

COPY dist/node_modules/supervisor /usr/local/lib/node_modules/supervisor

RUN ln -s /usr/local/lib/node_modules/opifex/bin/opifex /usr/local/bin/opifex && \
    ln -s /usr/local/lib/node_modules/supervisor/lib/cli-wrapper.js /usr/local/bin/supervisor

WORKDIR /usr/local/lib/node_modules
 
ENTRYPOINT [ "/usr/local/bin/supervisor", "--", "/usr/local/bin/opifex" ]
