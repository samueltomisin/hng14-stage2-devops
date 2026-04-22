import redis
import time
import os


r = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", 6379))
)

def process_job(job_id):
    try:
        print(f"Processing job {job_id}")
        time.sleep(2)
        r.hset(f"job:{job_id}", "status", "completed")
        print(f"Done: {job_id}")
    except Exception as e:
        print(f"ERROR processing {job_id}: {e}")
        r.hset(f"job:{job_id}", "status", "failed")

while True:
    job = r.brpop("job", timeout=5)
    if job:
        _, job_id = job
        process_job(job_id.decode())