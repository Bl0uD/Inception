all:
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

down-v:
	docker compose -f srcs/docker-compose.yml down -v

re: down all

clean: down
	docker system prune -af

fclean: clean
	docker volume prune -f

reset: down
	sudo rm -rf $(HOME)/data

.PHONY: all down re clean fclean reset

dev: fclean
		@echo "Adding files from current directory only..."
		@git add . && git diff --cached --quiet || (git commit -m "Inception - auto/dev" && git push) || echo "No changes to commit"