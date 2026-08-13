# Organiq MCP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a TypeScript MCP server in `mcp/` that exposes the Organiq API as 27 tools for use with Claude Code via stdio transport.

**Architecture:** Thin HTTP wrapper — one tool module per domain (`auth`, `inbox`, `tasks`, `reminders`, `events`, `shopping`, `agenda`), a central `client.ts` that manages auth and HTTP calls, and an `index.ts` entry point that wires everything together.

**Tech Stack:** TypeScript 5, Node.js 18+, `@modelcontextprotocol/sdk ^1.0.0`, native `fetch`

> **Note:** Tests are explicitly out of scope for v1 (per spec). No test steps are included.

---

## File Map

| File | Responsibility |
|------|---------------|
| `mcp/package.json` | Dependencies, build/start scripts |
| `mcp/tsconfig.json` | TypeScript compiler config |
| `mcp/.env.example` | Documented env vars |
| `mcp/src/types.ts` | All API response/request types |
| `mcp/src/client.ts` | HTTP client, auth state, `initAuth()`, `apiRequest()`, `login()` |
| `mcp/src/tools/auth.ts` | `auth_me`, `auth_login` |
| `mcp/src/tools/inbox.ts` | `inbox_list/get/create/reprocess/confirm/dismiss` |
| `mcp/src/tools/tasks.ts` | `tasks_list/create/update/delete` |
| `mcp/src/tools/reminders.ts` | `reminders_list/create/update/delete` |
| `mcp/src/tools/events.ts` | `events_list/create/update/delete` |
| `mcp/src/tools/shopping.ts` | `shopping_lists_*` and `shopping_items_*` |
| `mcp/src/tools/agenda.ts` | `agenda_get` |
| `mcp/src/index.ts` | Server bootstrap, tool registration, request dispatch |
| `mcp/README.md` | Build instructions and Claude Code setup |

---

## Task 1: Scaffold the project

**Files:**
- Create: `mcp/package.json`
- Create: `mcp/tsconfig.json`
- Create: `mcp/.env.example`

- [ ] **Step 1: Create `mcp/package.json`**

```json
{
  "name": "organiq-mcp",
  "version": "0.1.0",
  "description": "MCP server for the Organiq API",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0"
  }
}
```

- [ ] **Step 2: Create `mcp/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 3: Create `mcp/.env.example`**

```bash
# Base URL of the Organiq API
ORGANIQ_BASE_URL=http://localhost:8080

# Option 1: provide a fixed JWT (takes precedence)
ORGANIQ_TOKEN=

# Option 2: provide credentials — the server will login automatically
ORGANIQ_EMAIL=
ORGANIQ_PASSWORD=
```

- [ ] **Step 4: Install dependencies**

```bash
cd mcp && npm install
```

Expected: `node_modules/` created, no errors.

- [ ] **Step 5: Commit**

```bash
cd mcp && git add package.json tsconfig.json .env.example package-lock.json
git commit -m "feat(mcp): scaffold TypeScript MCP project"
```

---

## Task 2: Shared types

**Files:**
- Create: `mcp/src/types.ts`

- [ ] **Step 1: Create `mcp/src/types.ts`**

```typescript
export interface FlagObject {
  id: string;
  name: string;
  color: string;
}

export interface SubflagObject {
  id: string;
  name: string;
  color: string;
}

export interface InboxItemObject {
  id: string;
  source: 'manual' | 'share' | 'ocr';
  rawText: string;
  rawMediaUrl: string | null;
  status:
    | 'NEW'
    | 'PROCESSING'
    | 'SUGGESTED'
    | 'NEEDS_REVIEW'
    | 'CONFIRMED'
    | 'DISMISSED';
  lastError: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AiSuggestionResponse {
  id: string;
  type: 'task' | 'reminder' | 'event' | 'shopping' | 'note';
  title: string;
  confidence: number;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  needsReview: boolean;
  payload: Record<string, unknown>;
  createdAt: string;
}

export interface InboxItemResponse extends InboxItemObject {
  suggestion: AiSuggestionResponse | null;
}

export interface TaskResponse {
  id: string;
  title: string;
  description: string | null;
  status: 'OPEN' | 'DONE';
  dueAt: string | null;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface ReminderResponse {
  id: string;
  title: string;
  status: 'OPEN' | 'DONE';
  remindAt: string | null;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface EventResponse {
  id: string;
  title: string;
  startAt: string | null;
  endAt: string | null;
  allDay: boolean;
  location: string | null;
  flag: FlagObject | null;
  subflag: SubflagObject | null;
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface ShoppingListObject {
  id: string;
  title: string;
  status: 'OPEN' | 'DONE' | 'ARCHIVED';
}

export interface ShoppingListResponse extends ShoppingListObject {
  sourceInboxItem: InboxItemObject | null;
  createdAt: string;
  updatedAt: string;
}

export interface ShoppingItemResponse {
  id: string;
  list: ShoppingListObject;
  title: string;
  quantity: string | null;
  checked: boolean;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  nextCursor: string | null;
}

export interface AuthUser {
  id: string;
  email: string;
  displayName: string;
  locale: string;
  timezone: string;
}

export interface AuthResponse {
  token: string;
  user: AuthUser;
}

export interface ConfirmResponse {
  type: 'task' | 'reminder' | 'event' | 'shopping';
  task?: TaskResponse;
  reminder?: ReminderResponse;
  event?: EventResponse;
  shoppingList?: ShoppingListResponse;
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/types.ts
git commit -m "feat(mcp): add shared API types"
```

---

## Task 3: HTTP client with auth

**Files:**
- Create: `mcp/src/client.ts`

- [ ] **Step 1: Create `mcp/src/client.ts`**

```typescript
import type { AuthResponse } from './types.js';

const baseUrl = process.env.ORGANIQ_BASE_URL ?? 'http://localhost:8080';
let token: string | null = null;

export async function login(email: string, password: string): Promise<AuthResponse> {
  const res = await fetch(`${baseUrl}/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  const data = (await res.json()) as AuthResponse & { error?: string };

  if (!res.ok) {
    throw new Error(`Login failed: ${data.error ?? res.statusText}`);
  }

  token = data.token;
  return data;
}

export async function initAuth(): Promise<void> {
  if (process.env.ORGANIQ_TOKEN) {
    token = process.env.ORGANIQ_TOKEN;
    return;
  }

  const email = process.env.ORGANIQ_EMAIL;
  const password = process.env.ORGANIQ_PASSWORD;

  if (!email || !password) {
    throw new Error(
      'Authentication required: set ORGANIQ_TOKEN, or both ORGANIQ_EMAIL and ORGANIQ_PASSWORD',
    );
  }

  await login(email, password);
}

export async function apiRequest<T>(
  method: string,
  path: string,
  body?: unknown,
): Promise<T> {
  if (!token) throw new Error('Not authenticated. Call initAuth() first.');

  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (res.status === 204) return undefined as T;

  const data = (await res.json()) as T & { error?: string };

  if (!res.ok) {
    throw new Error(data.error ?? `HTTP ${res.status}`);
  }

  return data;
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/client.ts
git commit -m "feat(mcp): add HTTP client with token/credential auth"
```

---

## Task 4: Auth tools

**Files:**
- Create: `mcp/src/tools/auth.ts`

- [ ] **Step 1: Create `mcp/src/tools/auth.ts`**

```typescript
import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest, login } from '../client.js';
import type { AuthResponse } from '../types.js';

export const authTools: Tool[] = [
  {
    name: 'auth_me',
    description:
      'Returns the profile of the currently authenticated Organiq user (id, email, displayName, locale, timezone). Use this to confirm which account is connected.',
    inputSchema: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
  {
    name: 'auth_login',
    description:
      'Logs in to Organiq with email and password, updating the active session token. Useful if you need to switch accounts during a session.',
    inputSchema: {
      type: 'object',
      properties: {
        email: { type: 'string', description: 'User email address' },
        password: { type: 'string', description: 'User password' },
      },
      required: ['email', 'password'],
    },
  },
];

export async function handleAuthTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'auth_me': {
      const result = await apiRequest<AuthResponse>('GET', '/v1/me');
      return JSON.stringify(result.user, null, 2);
    }

    case 'auth_login': {
      const result = await login(args.email as string, args.password as string);
      return JSON.stringify(
        { message: 'Login successful', user: result.user },
        null,
        2,
      );
    }

    default:
      throw new Error(`Unknown auth tool: ${name}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/tools/auth.ts
git commit -m "feat(mcp): add auth tools (auth_me, auth_login)"
```

---

## Task 5: Inbox tools

**Files:**
- Create: `mcp/src/tools/inbox.ts`

- [ ] **Step 1: Create `mcp/src/tools/inbox.ts`**

```typescript
import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type {
  ConfirmResponse,
  InboxItemResponse,
  PaginatedResponse,
} from '../types.js';

export const inboxTools: Tool[] = [
  {
    name: 'inbox_list',
    description:
      'Lists items in the Organiq inbox. Filter by status (NEW, PROCESSING, SUGGESTED, NEEDS_REVIEW, CONFIRMED, DISMISSED) or source (manual, share, ocr). Supports pagination via limit and cursor.',
    inputSchema: {
      type: 'object',
      properties: {
        status: {
          type: 'string',
          enum: ['NEW', 'PROCESSING', 'SUGGESTED', 'NEEDS_REVIEW', 'CONFIRMED', 'DISMISSED'],
          description: 'Filter by item status',
        },
        source: {
          type: 'string',
          enum: ['manual', 'share', 'ocr'],
          description: 'Filter by item source',
        },
        limit: { type: 'number', description: 'Number of items to return' },
        cursor: { type: 'string', description: 'Pagination cursor from previous response' },
      },
      required: [],
    },
  },
  {
    name: 'inbox_get',
    description:
      'Gets a single inbox item by ID, including the AI suggestion if one exists (type, title, confidence, payload).',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'inbox_create',
    description:
      'Creates a new raw item in the inbox. The item starts with status NEW. Use inbox_reprocess to trigger AI classification afterwards.',
    inputSchema: {
      type: 'object',
      properties: {
        rawText: { type: 'string', description: 'The raw text to add to the inbox' },
        source: {
          type: 'string',
          enum: ['manual', 'share', 'ocr'],
          description: 'Source of the item (default: manual)',
        },
      },
      required: ['rawText'],
    },
  },
  {
    name: 'inbox_reprocess',
    description:
      'Sends an inbox item to the AI for (re)classification. Updates the item status to SUGGESTED or NEEDS_REVIEW and stores the AI suggestion. Requires the AI client to be configured on the server.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'inbox_confirm',
    description:
      'Confirms an inbox item, creating the final entity (task, reminder, event, or shopping list). The item status changes to CONFIRMED. ' +
      'Payload per type — task: { dueAt? }, reminder: { at (required RFC3339) }, event: { start (RFC3339), end?, allDay }, shopping: { items: [{ title, quantity? }] }',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
        type: {
          type: 'string',
          enum: ['task', 'reminder', 'event', 'shopping'],
          description: 'Type of entity to create',
        },
        title: { type: 'string', description: 'Title of the final entity' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
        payload: {
          type: 'object',
          description:
            'Type-specific payload. task: {dueAt?}. reminder: {at}. event: {start, end?, allDay}. shopping: {items:[{title,quantity?}]}',
        },
      },
      required: ['id', 'type', 'title', 'payload'],
    },
  },
  {
    name: 'inbox_dismiss',
    description: 'Dismisses an inbox item, marking it as DISMISSED. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Inbox item UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleInboxTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'inbox_list': {
      const params = new URLSearchParams();
      if (args.status) params.set('status', args.status as string);
      if (args.source) params.set('source', args.source as string);
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<InboxItemResponse>>(
        'GET',
        `/v1/inbox-items${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_get': {
      const result = await apiRequest<InboxItemResponse>(
        'GET',
        `/v1/inbox-items/${args.id}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_create': {
      const result = await apiRequest<InboxItemResponse>('POST', '/v1/inbox-items', {
        rawText: args.rawText,
        source: args.source ?? 'manual',
      });
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_reprocess': {
      const result = await apiRequest<InboxItemResponse>(
        'POST',
        `/v1/inbox-items/${args.id}/reprocess`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_confirm': {
      const result = await apiRequest<ConfirmResponse>(
        'POST',
        `/v1/inbox-items/${args.id}/confirm`,
        {
          type: args.type,
          title: args.title,
          flagId: args.flagId ?? null,
          subflagId: args.subflagId ?? null,
          payload: args.payload,
        },
      );
      return JSON.stringify(result, null, 2);
    }

    case 'inbox_dismiss': {
      await apiRequest<void>('POST', `/v1/inbox-items/${args.id}/dismiss`);
      return JSON.stringify({ message: 'Item dismissed successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown inbox tool: ${name}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/tools/inbox.ts
git commit -m "feat(mcp): add inbox tools (list/get/create/reprocess/confirm/dismiss)"
```

---

## Task 6: Tasks tools

**Files:**
- Create: `mcp/src/tools/tasks.ts`

- [ ] **Step 1: Create `mcp/src/tools/tasks.ts`**

```typescript
import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { PaginatedResponse, TaskResponse } from '../types.js';

export const taskTools: Tool[] = [
  {
    name: 'tasks_list',
    description:
      'Lists all tasks for the authenticated user. Returns id, title, description, status (OPEN/DONE), dueAt, flag, subflag, and sourceInboxItem. Supports pagination via limit and cursor.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of tasks to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'tasks_create',
    description:
      'Creates a new task directly (without going through the inbox). Use this when the user explicitly says they want to create a task.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Task title' },
        description: { type: 'string', description: 'Optional task description' },
        dueAt: { type: 'string', description: 'Optional due date in RFC3339 format' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
      },
      required: ['title'],
    },
  },
  {
    name: 'tasks_update',
    description:
      'Updates an existing task. Only provided fields are changed. Use status DONE to mark as complete, OPEN to reopen.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Task UUID' },
        title: { type: 'string', description: 'New title' },
        description: { type: 'string', description: 'New description' },
        status: { type: 'string', enum: ['OPEN', 'DONE'], description: 'New status' },
        dueAt: { type: 'string', description: 'New due date (RFC3339) or null to clear' },
        flagId: { type: 'string', description: 'New flag UUID or null to clear' },
        subflagId: { type: 'string', description: 'New subflag UUID or null to clear' },
      },
      required: ['id'],
    },
  },
  {
    name: 'tasks_delete',
    description: 'Permanently deletes a task. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Task UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleTasksTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'tasks_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<TaskResponse>>(
        'GET',
        `/v1/tasks${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'tasks_create': {
      const result = await apiRequest<TaskResponse>('POST', '/v1/tasks', {
        title: args.title,
        description: args.description ?? null,
        dueAt: args.dueAt ?? null,
        flagId: args.flagId ?? null,
        subflagId: args.subflagId ?? null,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'tasks_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.description !== undefined) body.description = args.description;
      if (args.status !== undefined) body.status = args.status;
      if (args.dueAt !== undefined) body.dueAt = args.dueAt;
      if (args.flagId !== undefined) body.flagId = args.flagId;
      if (args.subflagId !== undefined) body.subflagId = args.subflagId;
      const result = await apiRequest<TaskResponse>('PATCH', `/v1/tasks/${args.id}`, body);
      return JSON.stringify(result, null, 2);
    }

    case 'tasks_delete': {
      await apiRequest<void>('DELETE', `/v1/tasks/${args.id}`);
      return JSON.stringify({ message: 'Task deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown tasks tool: ${name}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/tools/tasks.ts
git commit -m "feat(mcp): add tasks tools (list/create/update/delete)"
```

---

## Task 7: Reminders tools

**Files:**
- Create: `mcp/src/tools/reminders.ts`

- [ ] **Step 1: Create `mcp/src/tools/reminders.ts`**

```typescript
import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { PaginatedResponse, ReminderResponse } from '../types.js';

export const reminderTools: Tool[] = [
  {
    name: 'reminders_list',
    description:
      'Lists all reminders for the authenticated user. Returns id, title, status (OPEN/DONE), remindAt, flag, subflag. Supports pagination via limit and cursor.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of reminders to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'reminders_create',
    description:
      'Creates a new reminder. The remindAt field is required and must be a valid RFC3339 datetime.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Reminder title' },
        remindAt: { type: 'string', description: 'When to remind, in RFC3339 format (required)' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
      },
      required: ['title', 'remindAt'],
    },
  },
  {
    name: 'reminders_update',
    description: 'Updates an existing reminder. Only provided fields are changed.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Reminder UUID' },
        title: { type: 'string', description: 'New title' },
        status: { type: 'string', enum: ['OPEN', 'DONE'], description: 'New status' },
        remindAt: { type: 'string', description: 'New remind datetime (RFC3339)' },
        flagId: { type: 'string', description: 'New flag UUID or null to clear' },
        subflagId: { type: 'string', description: 'New subflag UUID or null to clear' },
      },
      required: ['id'],
    },
  },
  {
    name: 'reminders_delete',
    description: 'Permanently deletes a reminder. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Reminder UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleRemindersTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'reminders_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<ReminderResponse>>(
        'GET',
        `/v1/reminders${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'reminders_create': {
      const result = await apiRequest<ReminderResponse>('POST', '/v1/reminders', {
        title: args.title,
        remindAt: args.remindAt,
        flagId: args.flagId ?? null,
        subflagId: args.subflagId ?? null,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'reminders_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.status !== undefined) body.status = args.status;
      if (args.remindAt !== undefined) body.remindAt = args.remindAt;
      if (args.flagId !== undefined) body.flagId = args.flagId;
      if (args.subflagId !== undefined) body.subflagId = args.subflagId;
      const result = await apiRequest<ReminderResponse>(
        'PATCH',
        `/v1/reminders/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'reminders_delete': {
      await apiRequest<void>('DELETE', `/v1/reminders/${args.id}`);
      return JSON.stringify({ message: 'Reminder deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown reminders tool: ${name}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/tools/reminders.ts
git commit -m "feat(mcp): add reminders tools (list/create/update/delete)"
```

---

## Task 8: Events tools

**Files:**
- Create: `mcp/src/tools/events.ts`

- [ ] **Step 1: Create `mcp/src/tools/events.ts`**

```typescript
import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { EventResponse, PaginatedResponse } from '../types.js';

export const eventTools: Tool[] = [
  {
    name: 'events_list',
    description:
      'Lists all calendar events for the authenticated user. Returns id, title, startAt, endAt, allDay, location, flag, subflag. Supports pagination.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of events to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'events_create',
    description:
      'Creates a new calendar event. startAt is required. endAt must be after startAt if provided. Use allDay: true for full-day events.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Event title' },
        startAt: { type: 'string', description: 'Start datetime in RFC3339 format (required)' },
        endAt: { type: 'string', description: 'End datetime in RFC3339 format' },
        allDay: { type: 'boolean', description: 'Whether this is an all-day event' },
        location: { type: 'string', description: 'Optional location string' },
        flagId: { type: 'string', description: 'Optional flag UUID' },
        subflagId: { type: 'string', description: 'Optional subflag UUID' },
      },
      required: ['title', 'startAt'],
    },
  },
  {
    name: 'events_update',
    description: 'Updates an existing event. Only provided fields are changed.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Event UUID' },
        title: { type: 'string', description: 'New title' },
        startAt: { type: 'string', description: 'New start datetime (RFC3339)' },
        endAt: { type: 'string', description: 'New end datetime (RFC3339) or null to clear' },
        allDay: { type: 'boolean', description: 'New allDay value' },
        location: { type: 'string', description: 'New location or null to clear' },
        flagId: { type: 'string', description: 'New flag UUID or null to clear' },
        subflagId: { type: 'string', description: 'New subflag UUID or null to clear' },
      },
      required: ['id'],
    },
  },
  {
    name: 'events_delete',
    description: 'Permanently deletes a calendar event. This action is irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Event UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleEventsTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'events_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<EventResponse>>(
        'GET',
        `/v1/events${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'events_create': {
      const result = await apiRequest<EventResponse>('POST', '/v1/events', {
        title: args.title,
        startAt: args.startAt,
        endAt: args.endAt ?? null,
        allDay: args.allDay ?? false,
        location: args.location ?? null,
        flagId: args.flagId ?? null,
        subflagId: args.subflagId ?? null,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'events_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.startAt !== undefined) body.startAt = args.startAt;
      if (args.endAt !== undefined) body.endAt = args.endAt;
      if (args.allDay !== undefined) body.allDay = args.allDay;
      if (args.location !== undefined) body.location = args.location;
      if (args.flagId !== undefined) body.flagId = args.flagId;
      if (args.subflagId !== undefined) body.subflagId = args.subflagId;
      const result = await apiRequest<EventResponse>(
        'PATCH',
        `/v1/events/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'events_delete': {
      await apiRequest<void>('DELETE', `/v1/events/${args.id}`);
      return JSON.stringify({ message: 'Event deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown events tool: ${name}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/tools/events.ts
git commit -m "feat(mcp): add events tools (list/create/update/delete)"
```

---

## Task 9: Shopping tools

**Files:**
- Create: `mcp/src/tools/shopping.ts`

- [ ] **Step 1: Create `mcp/src/tools/shopping.ts`**

```typescript
import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type {
  PaginatedResponse,
  ShoppingItemResponse,
  ShoppingListResponse,
} from '../types.js';

export const shoppingTools: Tool[] = [
  {
    name: 'shopping_lists_list',
    description:
      'Lists all shopping lists for the authenticated user. Returns id, title, status (OPEN/DONE/ARCHIVED). Supports pagination.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of lists to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: [],
    },
  },
  {
    name: 'shopping_lists_create',
    description: 'Creates a new shopping list with the given title.',
    inputSchema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Shopping list title' },
      },
      required: ['title'],
    },
  },
  {
    name: 'shopping_lists_update',
    description:
      'Updates a shopping list title or status. Status values: OPEN, DONE, ARCHIVED.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping list UUID' },
        title: { type: 'string', description: 'New title' },
        status: {
          type: 'string',
          enum: ['OPEN', 'DONE', 'ARCHIVED'],
          description: 'New status',
        },
      },
      required: ['id'],
    },
  },
  {
    name: 'shopping_lists_delete',
    description: 'Permanently deletes a shopping list and all its items. Irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping list UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'shopping_items_list',
    description: 'Lists all items in a shopping list. Returns id, title, quantity, checked, sortOrder.',
    inputSchema: {
      type: 'object',
      properties: {
        listId: { type: 'string', description: 'Shopping list UUID' },
        limit: { type: 'number', description: 'Number of items to return' },
        cursor: { type: 'string', description: 'Pagination cursor' },
      },
      required: ['listId'],
    },
  },
  {
    name: 'shopping_items_create',
    description: 'Adds a new item to a shopping list.',
    inputSchema: {
      type: 'object',
      properties: {
        listId: { type: 'string', description: 'Shopping list UUID' },
        title: { type: 'string', description: 'Item name' },
        quantity: { type: 'string', description: 'Optional quantity (e.g. "2", "500g")' },
      },
      required: ['listId', 'title'],
    },
  },
  {
    name: 'shopping_items_update',
    description:
      'Updates a shopping item. Use checked: true to mark as bought, false to unmark. title and quantity can also be changed.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping item UUID' },
        title: { type: 'string', description: 'New item name' },
        quantity: { type: 'string', description: 'New quantity or null to clear' },
        checked: { type: 'boolean', description: 'Whether the item has been picked up' },
      },
      required: ['id'],
    },
  },
  {
    name: 'shopping_items_delete',
    description: 'Permanently deletes a shopping item. Irreversible.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Shopping item UUID' },
      },
      required: ['id'],
    },
  },
];

export async function handleShoppingTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'shopping_lists_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<ShoppingListResponse>>(
        'GET',
        `/v1/shopping-lists${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_lists_create': {
      const result = await apiRequest<ShoppingListResponse>('POST', '/v1/shopping-lists', {
        title: args.title,
      });
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_lists_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.status !== undefined) body.status = args.status;
      const result = await apiRequest<ShoppingListResponse>(
        'PATCH',
        `/v1/shopping-lists/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_lists_delete': {
      await apiRequest<void>('DELETE', `/v1/shopping-lists/${args.id}`);
      return JSON.stringify({ message: 'Shopping list deleted successfully' }, null, 2);
    }

    case 'shopping_items_list': {
      const params = new URLSearchParams();
      if (args.limit) params.set('limit', String(args.limit));
      if (args.cursor) params.set('cursor', args.cursor as string);
      const qs = params.toString();
      const result = await apiRequest<PaginatedResponse<ShoppingItemResponse>>(
        'GET',
        `/v1/shopping-lists/${args.listId}/items${qs ? `?${qs}` : ''}`,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_items_create': {
      const result = await apiRequest<ShoppingItemResponse>(
        'POST',
        `/v1/shopping-lists/${args.listId}/items`,
        { title: args.title, quantity: args.quantity ?? null },
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_items_update': {
      const body: Record<string, unknown> = {};
      if (args.title !== undefined) body.title = args.title;
      if (args.quantity !== undefined) body.quantity = args.quantity;
      if (args.checked !== undefined) body.checked = args.checked;
      const result = await apiRequest<ShoppingItemResponse>(
        'PATCH',
        `/v1/shopping-items/${args.id}`,
        body,
      );
      return JSON.stringify(result, null, 2);
    }

    case 'shopping_items_delete': {
      await apiRequest<void>('DELETE', `/v1/shopping-items/${args.id}`);
      return JSON.stringify({ message: 'Shopping item deleted successfully' }, null, 2);
    }

    default:
      throw new Error(`Unknown shopping tool: ${name}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/tools/shopping.ts
git commit -m "feat(mcp): add shopping tools (lists + items CRUD)"
```

---

## Task 10: Agenda tool

**Files:**
- Create: `mcp/src/tools/agenda.ts`

- [ ] **Step 1: Create `mcp/src/tools/agenda.ts`**

```typescript
import type { Tool } from '@modelcontextprotocol/sdk/types.js';
import { apiRequest } from '../client.js';
import type { EventResponse, ReminderResponse, TaskResponse } from '../types.js';

interface AgendaResponse {
  events: EventResponse[];
  tasks: TaskResponse[];
  reminders: ReminderResponse[];
}

export const agendaTools: Tool[] = [
  {
    name: 'agenda_get',
    description:
      'Returns a unified view of the user\'s agenda: events, tasks, and reminders in a single call. Use this when the user asks "what do I have coming up", "show my schedule", or wants an overview of their day/week.',
    inputSchema: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
];

export async function handleAgendaTool(
  name: string,
  _args: Record<string, unknown>,
): Promise<string> {
  switch (name) {
    case 'agenda_get': {
      const result = await apiRequest<AgendaResponse>('GET', '/v1/agenda');
      return JSON.stringify(result, null, 2);
    }

    default:
      throw new Error(`Unknown agenda tool: ${name}`);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mcp/src/tools/agenda.ts
git commit -m "feat(mcp): add agenda_get tool (unified events/tasks/reminders view)"
```

---

## Task 11: Entry point and wiring

**Files:**
- Create: `mcp/src/index.ts`

- [ ] **Step 1: Create `mcp/src/index.ts`**

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { initAuth } from './client.js';
import { agendaTools, handleAgendaTool } from './tools/agenda.js';
import { authTools, handleAuthTool } from './tools/auth.js';
import { eventTools, handleEventsTool } from './tools/events.js';
import { inboxTools, handleInboxTool } from './tools/inbox.js';
import { reminderTools, handleRemindersTool } from './tools/reminders.js';
import { shoppingTools, handleShoppingTool } from './tools/shopping.js';
import { taskTools, handleTasksTool } from './tools/tasks.js';

await initAuth();

const server = new Server(
  { name: 'organiq', version: '0.1.0' },
  { capabilities: { tools: {} } },
);

const allTools = [
  ...authTools,
  ...inboxTools,
  ...taskTools,
  ...reminderTools,
  ...eventTools,
  ...shoppingTools,
  ...agendaTools,
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: allTools }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const safeArgs = (args ?? {}) as Record<string, unknown>;

  try {
    let result: string;

    if (name.startsWith('auth_')) {
      result = await handleAuthTool(name, safeArgs);
    } else if (name.startsWith('inbox_')) {
      result = await handleInboxTool(name, safeArgs);
    } else if (name.startsWith('tasks_')) {
      result = await handleTasksTool(name, safeArgs);
    } else if (name.startsWith('reminders_')) {
      result = await handleRemindersTool(name, safeArgs);
    } else if (name.startsWith('events_')) {
      result = await handleEventsTool(name, safeArgs);
    } else if (name.startsWith('shopping_')) {
      result = await handleShoppingTool(name, safeArgs);
    } else if (name === 'agenda_get') {
      result = await handleAgendaTool(name, safeArgs);
    } else {
      throw new Error(`Unknown tool: ${name}`);
    }

    return { content: [{ type: 'text', text: result }] };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      content: [{ type: 'text', text: `Error: ${message}` }],
      isError: true,
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

- [ ] **Step 2: Build the project**

```bash
cd mcp && npm run build
```

Expected: `dist/` folder created with compiled JS files. No TypeScript errors.

If build fails with module resolution errors, ensure `tsconfig.json` has `"moduleResolution": "Node16"` and all imports end in `.js`.

- [ ] **Step 3: Smoke test (requires a running API)**

```bash
cd mcp
ORGANIQ_BASE_URL=http://localhost:8080 ORGANIQ_TOKEN=<your-jwt> node dist/index.js
```

Expected: process starts and waits (no output to stdout, which is reserved for MCP protocol). Press Ctrl+C to stop.

- [ ] **Step 4: Commit**

```bash
git add mcp/src/index.ts mcp/dist/
git commit -m "feat(mcp): add entry point, wire all tools, build"
```

---

## Task 12: README and Claude Code setup instructions

**Files:**
- Create: `mcp/README.md`

- [ ] **Step 1: Create `mcp/README.md`**

````markdown
# Organiq MCP Server

MCP server that exposes the [Organiq](../README.md) API as tools for Claude Code and other MCP-compatible clients.

Runs locally via stdio — no hosting required.

## Prerequisites

- Node.js 18+
- A running Organiq API (local or production on Render)
- A valid JWT token **or** account credentials

## Setup

### 1. Install dependencies and build

```bash
cd mcp
npm install
npm run build
```

### 2. Configure Claude Code

Add the following to your Claude Code MCP settings.

**Option A — Claude Code CLI** (`~/.claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "organiq": {
      "command": "node",
      "args": ["/absolute/path/to/organiq/mcp/dist/index.js"],
      "env": {
        "ORGANIQ_BASE_URL": "https://your-api.onrender.com",
        "ORGANIQ_TOKEN": "your-jwt-here"
      }
    }
  }
}
```

**Option B — login with credentials** (if you don't have a static token):

```json
{
  "mcpServers": {
    "organiq": {
      "command": "node",
      "args": ["/absolute/path/to/organiq/mcp/dist/index.js"],
      "env": {
        "ORGANIQ_BASE_URL": "https://your-api.onrender.com",
        "ORGANIQ_EMAIL": "you@example.com",
        "ORGANIQ_PASSWORD": "yourpassword"
      }
    }
  }
}
```

### 3. Restart Claude Code

The `organiq` tools will appear in Claude Code's tool list.

## Available Tools (27)

| Group | Tools |
|-------|-------|
| Auth | `auth_me`, `auth_login` |
| Inbox | `inbox_list`, `inbox_get`, `inbox_create`, `inbox_reprocess`, `inbox_confirm`, `inbox_dismiss` |
| Tasks | `tasks_list`, `tasks_create`, `tasks_update`, `tasks_delete` |
| Reminders | `reminders_list`, `reminders_create`, `reminders_update`, `reminders_delete` |
| Events | `events_list`, `events_create`, `events_update`, `events_delete` |
| Shopping | `shopping_lists_list`, `shopping_lists_create`, `shopping_lists_update`, `shopping_lists_delete`, `shopping_items_list`, `shopping_items_create`, `shopping_items_update`, `shopping_items_delete` |
| Agenda | `agenda_get` |

## Development

```bash
cd mcp
npm run dev   # run without building (uses tsx)
npm run build # compile to dist/
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ORGANIQ_BASE_URL` | Yes | API base URL (e.g. `http://localhost:8080`) |
| `ORGANIQ_TOKEN` | One of these two options | Fixed JWT token |
| `ORGANIQ_EMAIL` + `ORGANIQ_PASSWORD` | One of these two options | Credentials for auto-login |
````

- [ ] **Step 2: Commit**

```bash
git add mcp/README.md
git commit -m "docs(mcp): add README with build and Claude Code setup instructions"
```

---

## Self-Review Checklist

- [x] All 27 tools from spec are implemented (auth: 2, inbox: 6, tasks: 4, reminders: 4, events: 4, shopping: 8, agenda: 1)
- [x] Auth logic: token fixed first, fallback to email/password login — covered in `client.ts` `initAuth()`
- [x] Error handling: API errors extracted from `error` field, network errors caught in `index.ts` dispatch
- [x] All types consistent across `types.ts` and tool files — `TaskResponse`, `ReminderResponse`, `EventResponse`, `ShoppingListResponse`, `ShoppingItemResponse`, `InboxItemResponse`, `ConfirmResponse`, `AuthResponse` all defined once in `types.ts` and imported
- [x] `auth_login` updates the module-level `token` via `login()` exported from `client.ts`
- [x] Pagination (limit/cursor) implemented in all list tools
- [x] `inbox_confirm` payload documented per type in tool description and inputSchema
- [x] No placeholders or TBDs
- [x] README covers build, both auth options, and Claude Code config
