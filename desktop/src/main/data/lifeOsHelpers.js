const DEFAULT_DASHBOARD_LAYOUT = [
  { id: 'w-prod', visible: true, size: 'm' },
  { id: 'w-fin', visible: true, size: 'm' },
  { id: 'w-hlth', visible: true, size: 's' },
  { id: 'w-well', visible: true, size: 's' },
  { id: 'w-mens', visible: true, size: 's' },
  { id: 'w-note', visible: true, size: 'm' },
  { id: 'w-rew', visible: true, size: 'm' },
];

const LIFEOS_SYNC_TABLES = [
  { name: 'projects', cols: ['id', 'name', 'status', 'progress', 'is_active', 'updated_at'] },
  { name: 'focus_sessions', cols: ['id', 'task_id', 'project_id', 'day', 'minutes', 'note', 'updated_at'] },
  { name: 'finance_envelopes', cols: ['id', 'name', 'monthly_budget', 'is_active', 'updated_at'] },
  { name: 'finance_entries', cols: ['id', 'day', 'type', 'category', 'amount', 'envelope_id', 'note', 'is_active', 'updated_at'] },
  { name: 'health_entries', cols: ['id', 'day', 'kind', 'name', 'value_num', 'value_num2', 'unit', 'note', 'is_active', 'updated_at'] },
  { name: 'wellness_entries', cols: ['id', 'day', 'mood', 'mood_score', 'energy', 'stress', 'sleep_hours', 'triggers_text', 'note', 'is_active', 'updated_at'] },
  { name: 'menstrual_entries', cols: ['id', 'day', 'phase', 'cycle_day', 'flow', 'symptoms_json', 'is_period_start', 'cycle_length', 'note', 'is_active', 'updated_at'] },
  { name: 'notes', cols: ['id', 'day', 'title', 'body', 'tags_json', 'is_active', 'updated_at'] },
];

const SENSITIVE_KEY_RE = /^(authorization|token|paired_token|code|pairing_code|secret)$/i;

function sanitizeAuditDetails(value) {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) return value.map(sanitizeAuditDetails);
  if (typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = SENSITIVE_KEY_RE.test(k) ? '[REDACTED]' : sanitizeAuditDetails(v);
    }
    return out;
  }
  if (typeof value === 'string') {
    return value.replace(/Bearer\s+[A-Za-z0-9._-]+/gi, 'Bearer [REDACTED]');
  }
  return value;
}

function parseJsonArray(raw) {
  if (Array.isArray(raw)) return raw;
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

function formatDay(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function resolveReportBounds(range, customStart, customEnd, todayStr) {
  const end = (range === 'custom' && customEnd) ? customEnd : todayStr;
  if (range === 'custom') {
    const start = (customStart && customStart <= end) ? customStart : end;
    return { start, end };
  }
  const [y, m, d] = todayStr.split('-').map(Number);
  const dt = new Date(y, m - 1, d);
  if (range === 'week') dt.setDate(dt.getDate() - 6);
  else if (range === 'month') dt.setDate(dt.getDate() - 29);
  else if (range === 'year') dt.setDate(dt.getDate() - 364);
  else dt.setDate(dt.getDate() - 6);
  return { start: formatDay(dt), end };
}

module.exports = {
  DEFAULT_DASHBOARD_LAYOUT,
  LIFEOS_SYNC_TABLES,
  sanitizeAuditDetails,
  parseJsonArray,
  resolveReportBounds,
};
