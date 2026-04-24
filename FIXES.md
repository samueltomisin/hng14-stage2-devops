1. api/main.py, 8, Redis host hardcoded as localhost, Use REDIS_HOST env var  
2. api/main.py, —, No /health endpoint, Added health route  
3. api/main.py, 16, HTTP 200 returned on missing job, Raise HTTP 404  
4. worker.py, 5, Redis host hardcoded as localhost, Use REDIS_HOST env var  
5. worker.py, 1, signal imported, never used, Removed unused import  
6. worker.py, 9, No error handling in process_job, Wrapped in try/except, sets failed status  
7. frontend/app.js, 6, API URL hardcoded as localhost, Use API_URL env var  
8. frontend/app.js, last, Port 3000 hardcoded, Use PORT env var  
9. frontend/views/index.html, pollJob, No error handling, infinite poll on error, Added error guard before polling  
10. api/requirements.txt, all, Unpinned dependencies, Pinned all to specific versions  
11. worker/requirements.txt, all, Unpinned dependencies, Pinned redis to specific version  
12. api/requirements.txt, —, Missing httpx for TestClient, Added httpx==0.27.0  
13. package.json, —, No ESLint config or lint script, Added eslint devDep + lint script + .eslintrc.json 