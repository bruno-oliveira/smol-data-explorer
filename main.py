import os

from litellm import completion

from smolagents import LiteLLMModel

from query_embedder import get_embedding_for, calculate_cosine_similarities
from query_embedder import get_embedding_for_queries

model = LiteLLMModel(
    model_id="ollama_chat/mistral-small", # This model is a bit weak for agentic behaviours though
    api_base=os.getenv("API_BASE", "http://localhost:11434"), # replace with 127.0.0.1:11434 or remote open-ai compatible server if necessary
    api_key="notused", # replace with API key if necessary
    num_ctx=8192 # ollama default is 2048 which will fail horribly. 8192 works for easy tasks, more is better. Check
    # https://huggingface.co/spaces/NyxKrage/LLM-Model-VRAM-Calculator to calculate how much VRAM this will need for the selected model.
)

query_examples = get_embedding_for_queries()
user_question = get_embedding_for("Listing of dividend payments received in last year?")
similar_queries = calculate_cosine_similarities(user_question,
                                                list(map(lambda x: (x[1],x[2]) ,query_examples)))

similar_queries_ = "Listing of dividend payments received in last year? Context:" + "\n\n".join(
    list(map(lambda x: x[0], similar_queries[0:3])))


response = completion(
    model=model.model_id,
    messages=[{"content": "Output only a SQL query to answer the user question, based on the examples given as "
                          "context.", "role":"system"},
              { "content": similar_queries_, "role": "user"}],
    stream=False,
)

print(response)