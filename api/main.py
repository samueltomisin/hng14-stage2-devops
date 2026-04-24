from fastapi import FastAPI, HTTPException
import redis
import uuid
import os


app = FastAPI()


def get_redis():
    return redis.Redis(
        host=os.getenv("REDIS_HOST", "redis"),
        port=int(os.getenv("REDIS_PORT", 6379))
    )


@app.post("/jobs")
def create_job():
    redis_client = get_redis()
    job_id = str(uuid.uuid4())
    redis_client.lpush("job", job_id)
    redis_client.hset(f"job:{job_id}", "status", "queued")
    return {"job_id": job_id}


@app.get("/jobs/{job_id}")
def get_job(job_id: str):
    redis_client = get_redis()
    status = redis_client.hget(f"job:{job_id}", "status")
    if not status:
        raise HTTPException(status_code=404, detail="Job not found")
    return {"job_id": job_id, "status": status.decode()}


@app.get("/health")
def health():
    return {"status": "ok"}
