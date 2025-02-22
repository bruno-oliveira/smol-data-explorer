-- Create a DB for RAG-assistance
SELECT 'CREATE DATABASE rag_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rag_db')\gexec
