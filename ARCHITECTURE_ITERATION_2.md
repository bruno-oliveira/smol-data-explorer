## Architecture iteration 2 - Using RAG with query examples

While using agents as a way to explore automated query execution "on the fly" is interesting, this of course, poses 
a significant security risk for any production-grade project, because the generated queries can be wrong or, in some 
cases, plain malicious, like issuing an update or a delete. While these cases can be constrained in the model 
prompts, such as, "only generate select queries, refuse to generate delete or update queries", this still leaves an 
attack vector exposed via prompt injection, etc.

A good way to fully mitigate this is to establish the DB connection with a readonly user that has only select 
privileges on a subset of tables to support the use cases needed.

The new architecture leverages only RAG and focuses exclusively on query generation and not automated execution via 
agents.