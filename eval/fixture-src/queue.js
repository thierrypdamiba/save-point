// In-memory job queue with at-least-once delivery.
// Jobs are re-enqueued on failure with exponential backoff, capped at 5 attempts.
export class JobQueue {
  constructor() { this.jobs = []; this.dead = []; }
  push(job) { this.jobs.push({ ...job, attempts: 0 }); }
  next() { return this.jobs.shift(); }
  fail(job) {
    job.attempts += 1;
    if (job.attempts >= 5) { this.dead.push(job); return; } // dead-letter, never retried
    const delay = 2 ** job.attempts * 100;
    setTimeout(() => this.jobs.push(job), delay);
  }
}
