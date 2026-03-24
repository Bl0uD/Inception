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

reset: down-v
	docker volume rm inception_mariadb_data inception_wordpress_data 2>/dev/null || true

.PHONY: all down down-v re clean fclean reset

dev: fclean
		@echo "Adding files from current directory only..."
		@git add . && git diff --cached --quiet || (git commit -m "Inception - auto/dev" && git push) || echo "No changes to commit"