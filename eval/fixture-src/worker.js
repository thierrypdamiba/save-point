import { JobQueue } from "./queue.js";
// Worker drains the queue serially; a throwing handler must not stop the loop.
export async function drain(queue, handler) {
  let job;
  while ((job = queue.next())) {
    try { await handler(job); }
    catch { queue.fail(job); }
  }
}
