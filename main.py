import json
import os
import psycopg2

from smolagents import CodeAgent, LiteLLMModel, tool, ToolCallingAgent

model = LiteLLMModel(
    model_id="ollama_chat/mistral-small", # This model is a bit weak for agentic behaviours though
    api_base=os.getenv("API_BASE", "http://localhost:11434"), # replace with 127.0.0.1:11434 or remote open-ai compatible server if necessary
    api_key="notused", # replace with API key if necessary
num_ctx=8192 # ollama default is 2048 which will fail horribly. 8192 works for easy tasks, more is better. Check https://huggingface.co/spaces/NyxKrage/LLM-Model-VRAM-Calculator to calculate how much VRAM this will need for the selected model.
)


@tool
def my_custom_tool(name: str) -> str:
    """A custom tool that returns a friendly greeting for a person
    Args:
     name: this is the name of the person to greet
    """
    return f"Hello dear {name}, pleased to meet you"

@tool
def schema_reader(file: str) -> str:
    """A custom tool that analyzes a DB schema and enables answering queries about it. Returns a query.
    Args:
     file: this is the file with the schema
    """
    with open("pgdump_db_schema.sql") as f:
        schema = f.readlines()
        return f"Based on {schema}, a query to solve the problem is..."

@tool
def query_executor(query: str) -> str:
    """A custom tool that executes a query and returns its result set
    Args:
     query: this is the query to execute
    """
    connection = psycopg2.connect(database="investment_db", user="admin", password="admin123", host="localhost",
                                  port=5432)


    cursor = connection.cursor()

    query = json.loads(query)["query"]
    cursor.execute(f"{query}")

    # Fetch all rows from database
    record = cursor.fetchall()

    print("Data from Database:- ", record)
    return "\n".join(list(map(lambda s: str(s), record)))


agent = ToolCallingAgent(tools=[my_custom_tool, schema_reader, query_executor], model=model,add_base_tools=False
                  , system_prompt="Think step by step and rely on your tools to produce useful responses to "
                                  "questions when suitable. You have the following tools available to you: {{"
                                  "managed_agents_descriptions}}. After thinking, output the final answer.")

run = agent.run(
    "What's the financial institution with the most transactions?"
)
