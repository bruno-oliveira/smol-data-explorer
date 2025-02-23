FROM postgres:15

# Environment variables will be provided via docker-compose
ENV POSTGRES_DB=investment_db
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=admin123

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql
COPY test_data.sql /docker-entrypoint-initdb.d/02-test_data.sql
COPY rag_db_creation.sql /docker-entrypoint-initdb.d/03-rag_db_creation.sql
COPY rag_db_tables.sql /docker-entrypoint-initdb.d/04-rag_db_tables.sql
COPY rag_db_test_data.sql /docker-entrypoint-initdb.d/05-rag_db_test_data.sql