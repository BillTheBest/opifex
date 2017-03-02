MODULE=opifex
USERNAME ?=
PASSWORD ?=
EMAIL ?=

clean:
	rm -f lib/*.js
	rm -rf node_modules

container:
	docker run --name $(MODULE)-builder -d -t -e USERNAME=$(USERNAME) -e PASSWORD=$(PASSWORD) -e EMAIL=$(EMAIL) -e REGISTRY=$(REGISTRY) -e MODULE=$(MODULE) -v `pwd`:/$(MODULE) node:6-slim bash
	docker exec -t $(MODULE)-builder /$(MODULE)/install
	docker cp $(MODULE)-builder:/usr/local/lib/node_modules ./dist
	docker kill $(MODULE)-builder
	docker rm $(MODULE)-builder
	docker build -t $(MODULE) .
