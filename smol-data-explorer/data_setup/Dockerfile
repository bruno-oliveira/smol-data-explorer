FROM postgres:15

# Environment variables will be provided via docker-compose
ENV POSTGRES_DB=investment_db
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=admin123

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql
COPY test_data.sql /docker-entrypoint-initdb.d/02-test_data.sql