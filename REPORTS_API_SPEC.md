# Evergreen – Reports & Export Backend API Specification

> Derived from the Flutter frontend implementation. Do NOT invent fields beyond
> what the frontend reads. All endpoints are relative to the configured base
> URL (default `https://evergreen-backend-lgmy.onrender.com/`).

## Authentication & common headers

- All endpoints require `Authorization: Bearer <jwt>` (JWT issued by `POST /auth/signIn`).
- Content-Type: `application/json`.
- Roles allowed (unless noted): Super Admin, EG Manager (and other authorised roles per `Permissions.canViewReports`).

## Common query parameters (date-range reports)

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `from` | ISO 8601 date-time string | optional | Range start (inclusive). |
| `to`   | ISO 8601 date-time string | optional | Range end (inclusive). |

Default range in the UI is "this month" (`from = first day of current month 00:00`, `to = now`).

---

## 1. Dashboard APIs

The Dashboard (Reports → "Dashboard" tab) is built from a single aggregated
`GET reports/dashboard` call plus the same data is reused by the Analytics
screen. The frontend's `ReportsDashboard` model expects:

### 1.1 `GET reports/dashboard`

**Purpose:** Aggregated KPI summary + recent activity for the Reports dashboard.

**Query params:** none (date range is implicit "all time" / "last 30 days" for SLA).

**Response (200):**
```json
{
  "success": 200,
  "data": {
    "tasksSummary": {
      "total": 1,
      "open": 0,
      "completed": 1,
      "overdue": 0
    },
    "techniciansSummary": {
      "total": 5,
      "active": 4,
      "avgPerformance": 85
    },
    "amcsSummary": {
      "total": 23,
      "active": 18,
      "expiringSoon": 3
    },
    "equipmentSummary": {
      "total": 12,
      "operational": 10,
      "needsAttention": 2
    },
    "slaCompliance": 92,
    "recentActivity": [
      {
        "type": "task",
        "description": "Ticket #1001 marked completed",
        "timestamp": "2026-11-14T10:30:00.000Z"
      }
    ]
  }
}
```

**Field types:**
- `tasksSummary.total/open/completed/overdue`: int
- `techniciansSummary.total/active/avgPerformance`: int
- `amcsSummary.total/active/expiringSoon`: int
- `equipmentSummary.total/operational/needsAttention`: int
- `slaCompliance`: int (percentage 0–100)
- `recentActivity`: array of `{ type: string, description: string, timestamp: ISO date-time string }`

**Underlying entities:** `tasks`, `user` (technicians), `company` (AMCs), `equipment`, `task` events for recent activity.

---

## 2. Task Summary APIs

### 2.1 `POST reports/tasks`

**Purpose:** Task counts by status/priority/call type + daily trend for a date range.

**Request body:**
```json
{
  "from": "2026-11-01T00:00:00.000Z",
  "to": "2026-11-30T23:59:59.999Z"
}
```

**Response (200):**
```json
{
  "success": 200,
  "data": {
    "totalTasks": 1,
    "openTasks": 0,
    "inProgressTasks": 0,
    "completedTasks": 1,
    "closedTasks": 0,
    "holdTasks": 0,
    "overdueCount": 0,
    "escalatedCount": 0,
    "avgResolutionHours": 24,
    "tasksByPriority": [
      { "priority": "high", "count": 1 }
    ],
    "tasksByCallType": [
      { "callType": "breakdown", "count": 1 }
    ],
    "tasksByStatus": [
      { "status": "completed", "count": 1 }
    ],
    "dailyTrend": [
      { "date": "2026-11-14", "created": 1, "completed": 1 }
    ]
  }
}
```

**Field types:**
- All counts: int
- `tasksByPriority`: array of `{ priority: string, count: int }`
- `tasksByCallType`: array of `{ callType: string, count: int }`
- `tasksByStatus`: array of `{ status: string, count: int }`
- `dailyTrend`: array of `{ date: string (YYYY-MM-DD), created: int, completed: int }`

**Underlying entities:** `task`, `task_user` (assignment/acceptance/completion timestamps), `equipment`, `company`, `call_type`.

---

## 3. SLA Compliance APIs

### 3.1 `POST reports/sla`

**Purpose:** SLA compliance metrics and breakdowns for a date range.

**Request body:**
```json
{
  "from": "2026-11-01T00:00:00.000Z",
  "to": "2026-11-30T23:59:59.999Z"
}
```

**Response (200):**
```json
{
  "success": 200,
  "data": {
    "totalTickets": 1,
    "withinSla": 1,
    "slaBreached": 0,
    "complianceRate": 100,
    "avgResponseTime": 30,
    "avgResolutionTime": 120,
    "complianceByPriority": [
      { "priority": "high", "total": 1, "compliant": 1, "rate": 100 }
    ],
    "complianceByTechnician": [
      { "technicianId": 5, "technicianName": "Raju", "total": 1, "compliant": 1, "rate": 100 }
    ],
    "breachReasons": [
      { "reason": "Delayed assignment", "count": 0 }
    ],
    "monthlyTrend": [
      { "month": "2026-11", "rate": 100 }
    ]
  }
}
```

**Field types:**
- `totalTickets/withinSla/slaBreached/complianceRate/avgResponseTime/avgResolutionTime`: int
- `complianceByPriority`: array of `{ priority: string, total: int, compliant: int, rate: int }`
- `complianceByTechnician`: array of `{ technicianId: int, technicianName: string, total: int, compliant: int, rate: int }`
- `breachReasons`: array of `{ reason: string, count: int }`
- `monthlyTrend`: array of `{ month: string (YYYY-MM), rate: int }`

**Underlying entities:** `task` (due_date, created_at, completed_at, closed_at), `task_user` (assigned_at, accepted_at), `technician`, `priority`.

---

## 4. Export APIs

### 4.1 `GET reports/dashboard` (CSV export)

**Purpose:** The frontend's "Export" button (Analytics) generates CSV client-side from the dashboard data. No dedicated export endpoint is required; the CSV is built in the browser from `ReportsDashboard.toCsv()`.

**If a server-side export is desired (future):**
- `GET reports/export?format=csv|xlsx|pdf&from=...&to=...`
- Response: binary file download with `Content-Disposition: attachment`.

### 4.2 Existing report endpoints (already defined above)
- `GET reports/dashboard` — Dashboard tab
- `POST reports/tasks` — Task Summary tab
- `POST reports/technicians` — Technician Performance tab
- `GET reports/amcs` — AMC Status tab
- `GET reports/equipment` — Equipment Health tab
- `POST reports/sla` — SLA Compliance tab

**Pagination:** None currently used by the frontend (full lists returned). If record counts grow, add `page`/`limit` query params and a `total` field in the response.

---

## 5. Additional report endpoints (used by other tabs)

### 5.1 `POST reports/technicians`

**Purpose:** Technician performance metrics.

**Request body:** `{ "from": "...", "to": "..." }`

**Response (200):**
```json
{
  "success": 200,
  "data": {
    "technicians": [
      {
        "id": 5,
        "name": "Raju",
        "totalAssigned": 10,
        "completed": 8,
        "inProgress": 1,
        "avgResolutionHours": 24,
        "avgRating": 4.5,
        "slaCompliance": 90,
        "escalations": 0
      }
    ],
    "topPerformers": [
      { "id": 5, "name": "Raju", "score": 95.0 }
    ],
    "averageResolutionTime": 24,
    "overallSlaCompliance": 90
  }
}
```

### 5.2 `GET reports/amcs`

**Purpose:** AMC status summary.

**Response (200):**
```json
{
  "success": 200,
  "data": {
    "totalAmcs": 23,
    "activeAmcs": 18,
    "expiringSoon": 3,
    "expired": 2,
    "renewalsDue": 3,
    "amcsByType": [
      { "type": "C AMC", "count": 10 }
    ],
    "amcsByServiceType": [
      { "serviceType": "AMC", "count": 14 }
    ],
    "expiringContracts": [
      {
        "companyId": 3,
        "companyName": "SAR 1",
        "endDate": "2026-10-04",
        "daysRemaining": 30
      }
    ],
    "monthlyRevenue": [
      { "month": "2026-11", "count": 5 }
    ]
  }
}
```

### 5.3 `GET reports/equipment`

**Purpose:** Equipment health summary.

**Response (200):**
```json
{
  "success": 200,
  "data": {
    "totalEquipment": 12,
    "operational": 10,
    "underMaintenance": 1,
    "faulty": 1,
    "retired": 0,
    "verifiedCount": 8,
    "unverifiedCount": 4,
    "equipmentByStatus": [
      { "status": "operational", "count": 10 }
    ],
    "equipmentByServiceType": [
      { "serviceType": "AMC", "count": 8 }
    ],
    "recentIssues": [
      {
        "equipmentId": 5,
        "equipmentName": "Oven",
        "issueCount": 2,
        "lastIssueDate": "2026-11-10"
      }
    ],
    "maintenanceDue": [
      {
        "equipmentId": 5,
        "equipmentName": "Oven",
        "companyName": "SAR 1",
        "dueDate": "2026-11-20"
      }
    ]
  }
}
```

---

## 6. Dashboard APIs (Analytics screen)

The mobile/web Dashboard uses these existing endpoints (already implemented in the backend):

| Method | Endpoint | Purpose | Response |
|--------|----------|---------|----------|
| GET | `user/getAllUser` | List users (role-scoped) | `{ data: [User] }` |
| POST | `user/getUserStats` | User counts by access level | `{ data: [{ access_level, count }] }` |
| POST | `user/getAllTasksCount` | Task counts by status | `{ data: { open, hold, in_progress, completed, closed } }` |
| GET | `user/getAllCompanies` | List companies (AMC count derived) | `{ data: [Company] }` |
| POST | `user/getAllEquipments` | List equipment | `{ data: [Equipment] }` |
| POST | `user/getMonthlyStats` | Monthly trends | `{ data: { tasksCreated, tasksClosed, companies, users } }` |
| POST | `user/companiesStats` | Companies created per month | `{ data: [{ month, count }] }` |

**Authentication:** `Authorization: Bearer <jwt>` (JWT from `POST /auth/signIn`).
**Role-based access:** Super Admin sees all; EG Manager sees their scope; other roles see their own data.

---

## 7. Common filters and authentication

### Date range filters
- `from` / `to`: ISO 8601 date-time strings (optional).
- Defaults: "this month" (`from = first day of current month`, `to = now`).
- Presets in UI: This Month, Last Month, Last 30 Days, Last 90 Days, This Year, Custom Range.

### Authentication
- `POST /auth/signIn` with `{ phone, password }` + `api-key` header → returns `{ access_token, data: { user } }`.
- All report endpoints require `Authorization: Bearer <access_token>`.
- Role check: Super Admin and EG Manager (and other authorised roles per `Permissions.canViewReports`).

### Error response format
```json
{
  "success": 400,
  "message": "error description",
  "status": 400
}
```

---

## Frontend files inspected

| File | Purpose |
|------|---------|
| `lib/features/reports/data/reports_provider.dart` | ReportsApi service + providers |
| `lib/features/reports/domain/models/report_models.dart` | All report data models |
| `lib/features/reports/presentation/screens/reports_screen.dart` | Reports UI (KPI cards, charts, filters, export) |
| `lib/features/dashboard/data/analytics_provider.dart` | Dashboard analytics aggregation |
| `lib/features/dashboard/data/dashboard_repository.dart` | Dashboard API calls |
| `lib/features/dashboard/presentation/screens/analytics_screen.dart` | Analytics screen UI |
| `lib/features/dashboard/presentation/screens/home_screen.dart` | Home dashboard |

## Missing information / needs confirmation

1. **Pagination**: The frontend does not pass `page`/`limit` to report endpoints. If the backend supports pagination, the contract should include `total` in the response.
2. **Export format**: The frontend currently generates CSV client-side. If server-side PDF/Excel export is needed, a dedicated `GET reports/export?format=...` endpoint is required (not yet defined).
3. **Date defaults**: Confirm whether `from`/`to` are required or optional, and the default range when omitted.
4. **Technician performance**: Confirm whether `getTechnicianPerformance` should filter by company/branch for non-admin roles.
5. **SLA compliance**: Confirm the SLA threshold (hours) and whether `avgResponseTime`/`avgResolutionTime` are in minutes or hours.
6. **Monthly trend**: Confirm the granularity (daily vs monthly) expected by `dailyTrend`/`monthlyTrend`.
7. **AMC revenue**: `monthlyRevenue` uses `count` field — confirm if it should be revenue amount (currency) instead of count.

---

**No code was modified. No commits or pushes.**