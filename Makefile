all: run


Dockerfile.personal:
	@./substitute

.db-deps:
	@docker build -t db-deps . && touch .db-deps

.db-dev: .db-deps Dockerfile.personal
	@docker build -t db-dev . -f Dockerfile.personal && touch .db-dev

run: .db-dev
	@docker run --rm -it -v `pwd`:/app -u $$USER -h dev.local db-dev

stop:
	@docker stop $(docker ps -a -q --filter ancestor=db-dev --format="{{.ID}}") 2>/dev/null || true

clean: stop
	@docker rmi -f db-dev
	@docker rmi -f db-deps
	@rm -f .db-deps
	@rm -f .db-dev
	@rm -f Dockerfile.personal
