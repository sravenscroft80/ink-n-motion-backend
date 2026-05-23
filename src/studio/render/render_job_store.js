const { logger } = require('../../utils/logger');

const JOB_TTL_MS = 60 * 60 * 1000;
const MAX_JOBS = 500;

/** @type {Map<string, object>} */
const jobs = new Map();

function pruneJobStore() {
  const now = Date.now();

  for (const [jobId, job] of jobs.entries()) {
    if (now - job.createdAt > JOB_TTL_MS) {
      jobs.delete(jobId);
    }
  }

  if (jobs.size <= MAX_JOBS) {
    return;
  }

  const sorted = [...jobs.entries()].sort((a, b) => a[1].createdAt - b[1].createdAt);
  const overflow = jobs.size - MAX_JOBS;

  for (let i = 0; i < overflow; i += 1) {
    jobs.delete(sorted[i][0]);
  }
}

function createJobId() {
  return `studio-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

/**
 * Registers a Studio render job for client polling.
 *
 * @param {{
 *   taskId: string,
 *   vendor?: string,
 *   styleId: string,
 *   subjectType: string,
 *   renderSpec?: object,
 *   status?: string,
 *   videoUrl?: string|null,
 *   error?: string|null
 * }} input
 */
function createJob(input) {
  pruneJobStore();

  const jobId = createJobId();
  const now = Date.now();

  const job = {
    jobId,
    taskId: input.taskId,
    vendor: input.vendor ?? 'kling',
    styleId: input.styleId,
    subjectType: input.subjectType,
    renderSpec: input.renderSpec ?? null,
    status: input.status ?? 'queued',
    videoUrl: input.videoUrl ?? null,
    error: input.error ?? null,
    createdAt: now,
    updatedAt: now,
  };

  jobs.set(jobId, job);

  logger.info('Render job registered', {
    jobId,
    taskId: job.taskId,
    vendor: job.vendor,
    styleId: job.styleId,
    subjectType: job.subjectType,
  });

  return job;
}

function getJob(jobId) {
  pruneJobStore();
  return jobs.get(jobId) ?? null;
}

function updateJob(jobId, updates) {
  const job = getJob(jobId);
  if (!job) return null;

  Object.assign(job, updates, { updatedAt: Date.now() });
  jobs.set(jobId, job);
  return job;
}

function toStatusPayload(job) {
  return {
    job_id: job.jobId,
    task_id: job.taskId,
    status: job.status,
    video_url: job.videoUrl,
    vendor: job.vendor,
    style_id: job.styleId,
    subject_type: job.subjectType,
    error: job.error,
    updated_at: new Date(job.updatedAt).toISOString(),
  };
}

module.exports = {
  createJob,
  getJob,
  updateJob,
  toStatusPayload,
};
