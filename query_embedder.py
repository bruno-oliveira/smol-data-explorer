import functools
from typing import Tuple, List

import numpy as np
import ollama
import psycopg2



def embed(questions: list[str]):
    return ollama.embed(model='snowflake-arctic-embed:33m', input=questions)


def retrieve_query_examples_for_rag():
    db_params = {
        'dbname': 'rag_db',
        'user': 'admin',
        'password': 'admin123',
        'host': 'localhost',
    }
    questions_to_embed = []
    try:
        conn = psycopg2.connect(**db_params)
        # Create a cursor object
        cursor = conn.cursor()

        query = "SELECT * FROM query_examples;"
        cursor.execute(query)
        rows = cursor.fetchall()

        for row in rows:
            questions_to_embed.append(row)

    except psycopg2.Error as e:
        print(f"Error: {e}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            
    return questions_to_embed

def calculate_cosine_similarities(
        question_vector: List[float],
        queries: List[Tuple[str, List[float]]]
) -> List[Tuple[str, List[float], float]]:
    """
    Calculate cosine similarities between a question vector and a list of query vectors.
    Each query is a tuple containing (text, vector).

    Args:
        question_vector (List[float]): The reference vector to compare against
        queries (List[Tuple[str, List[float]]]): List of (text, vector) pairs to compare

    Returns:
        List[Tuple[str, List[float], float]]: List of (text, vector, similarity) tuples
        sorted by similarity in descending order
    """
    # Convert question vector to numpy array
    question_array = np.array(question_vector)

    # Extract query vectors and convert to numpy array
    query_vectors = np.array([vector for _, vector in queries])

    # Calculate the magnitude of the question vector
    question_magnitude = np.linalg.norm(question_array)

    # Calculate the magnitude of each query vector
    query_magnitudes = np.linalg.norm(query_vectors, axis=1)

    # Calculate dot products between question and all queries
    dot_products = np.dot(query_vectors, question_array)

    # Calculate cosine similarities
    similarities = dot_products / (question_magnitude * query_magnitudes)

    # Create list of (text, vector, similarity) tuples
    result = [(text, vector, sim) for (text, vector), sim in zip(queries, similarities)]

    # Sort by similarity in descending order
    sorted_result = sorted(result, key=lambda x: x[2], reverse=True)

    return sorted_result

@functools.cache
def get_query_example_embeddings() -> dict[str,list[float]]:
    print("Computing embeddings for query examples")
    return embed(list(map(lambda x: x[0], embedded_example_queries)))

@functools.cache
def get_embedding_for(question:str) -> list[float]:
    return embed([question])['embeddings'][0]

@functools.cache
def get_embedding_for_queries() -> List[Tuple[str, str, List[float]]]:

    embeddings_values = embed(list(map(lambda x: x[0], embedded_example_queries))).embeddings
    answer = []
    for i in range(len(embedded_example_queries)):
        answer.append((embedded_example_queries[i][0], embedded_example_queries[i][1], embeddings_values[i]))
    return answer

if name:="__main__":
    embedded_example_queries = retrieve_query_examples_for_rag()
