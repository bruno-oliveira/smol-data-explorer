import json
import os

import psycopg2
from litellm import completion

from smolagents import LiteLLMModel, tool, ToolCallingAgent, TOOL_CALLING_SYSTEM_PROMPT

model = LiteLLMModel(
    model_id="ollama_chat/mistral-small", # This model is a bit weak for agentic behaviours though
    api_base=os.getenv("API_BASE", "http://localhost:11434"), # replace with 127.0.0.1:11434 or remote open-ai compatible server if necessary
    api_key="notused", # replace with API key if necessary
num_ctx=8192 # ollama default is 2048 which will fail horribly. 8192 works for easy tasks, more is better. Check
    # https://huggingface.co/spaces/NyxKrage/LLM-Model-VRAM-Calculator to calculate how much VRAM this will need for the selected model.
)


@tool
def my_custom_tool(name: str) -> str:
    """A custom tool that returns a friendly greeting for a person
    Args:
     name: this is the name of the person to greet
    """
    return f"Hello dear {name}, pleased to meet you"

# agent = ToolCallingAgent(tools=[query_builder, query_executor], model=model,add_base_tools=False
#                   , system_prompt=TOOL_CALLING_SYSTEM_PROMPT+"\nYou have the following extra examples: "+loadExamples())
#
# run = agent.run(
#     "How many financial institutions have registered more than 10 transactions?"
# )
#
#


response = completion(
    model=model.model_id,
    messages=[{ "content": "Hello, what model are you?","role": "user"}],
    stream=False,
)

print(response.choices)

