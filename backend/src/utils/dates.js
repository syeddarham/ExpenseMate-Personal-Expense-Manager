/** Date helpers shared by budget and analytics controllers (server local time). */

/** First day of the month containing `date`. */
function startOfMonth(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function addMonths(date, n) {
  return new Date(date.getFullYear(), date.getMonth() + n, 1);
}

/** Parses "YYYY-MM"; falls back to the current month. */
function parseMonth(value) {
  if (typeof value === 'string' && /^\d{4}-(0[1-9]|1[0-2])$/.test(value)) {
    const [y, m] = value.split('-').map(Number);
    return new Date(y, m - 1, 1);
  }
  return startOfMonth(new Date());
}

/** Formats a Date as the MySQL DATE string YYYY-MM-DD (local). */
function toSqlDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Returns the [start, end) range and bucket definitions for an analytics period.
 * period: day | week | month | year
 */
function periodRange(period, now = new Date()) {
  const y = now.getFullYear();
  const m = now.getMonth();
  const d = now.getDate();
  const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  if (period === 'day') {
    const start = new Date(y, m, d);
    const buckets = [];
    for (let h = 0; h < 24; h += 3) {
      buckets.push({
        label: `${String(h).padStart(2, '0')}h`,
        start: new Date(y, m, d, h),
        end: new Date(y, m, d, h + 3),
      });
    }
    return { start, end: new Date(y, m, d + 1), buckets };
  }

  if (period === 'week') {
    const start = new Date(y, m, d - 6);
    const buckets = [];
    for (let i = 0; i < 7; i++) {
      const bStart = new Date(y, m, d - 6 + i);
      buckets.push({ label: weekdays[bStart.getDay()], start: bStart, end: new Date(y, m, d - 6 + i + 1) });
    }
    return { start, end: new Date(y, m, d + 1), buckets };
  }

  if (period === 'year') {
    const buckets = months.map((label, i) => ({ label, start: new Date(y, i, 1), end: new Date(y, i + 1, 1) }));
    return { start: new Date(y, 0, 1), end: new Date(y + 1, 0, 1), buckets };
  }

  // month (default): weekly buckets inside the current month
  const start = new Date(y, m, 1);
  const end = new Date(y, m + 1, 1);
  const lastDay = new Date(y, m + 1, 0).getDate();
  const buckets = [];
  for (let day = 1, w = 1; day <= lastDay; day += 7, w++) {
    buckets.push({
      label: `W${w}`,
      start: new Date(y, m, day),
      end: new Date(y, m, Math.min(day + 7, lastDay + 1)),
    });
  }
  return { start, end, buckets };
}

module.exports = { startOfMonth, addMonths, parseMonth, toSqlDate, periodRange };
