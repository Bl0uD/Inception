all:
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

re: down all

clean: down
	docker system prune -af

fclean: clean
	docker volume prune -f

.PHONY: all down re clean fclean

dev: fclean
		@echo "Adding files from current directory only..."
		@git add . && git diff --cached --quiet || (git commit -m "Inception - auto/dev" && git push) || echo "No changes to commit"