# docusign-integration

Rails 8 multi-tenant DocuSign integration service.

## Stack
- Ruby 4.0.9 / Rails 8.1.4
- PostgreSQL
- Solid Queue + Mission Control Jobs
- Solid Cache / Solid Cable
- Active Storage (local dev, S3 ready)

## Engine Dependencies
Gemfile uses the same git-style dependency declaration as `easy_biz_host_app`.
Use local overrides before install:

```bash
bundle config set local.omni_account /home/andersen/as_projects/omni_engines/omni_account
bundle config set local.omni_pay /home/andersen/as_projects/omni_engines/omni_pay
bundle config set local.omni_region /home/andersen/as_projects/omni_engines/omni_region
bundle config set local.omni_role /home/andersen/as_projects/omni_engines/omni_role
bundle config set local.wechat_open_platform_proxy /home/andersen/as_projects/wechat_open_platform/wechat_open_platform_proxy
bundle config set local.wechat_vendor_platform_proxy /home/andersen/as_projects/wechat_vendor_platform/wechat_vendor_platform_proxy
bundle config set local.wechat_work_platform_proxy /home/andersen/as_projects/wechat_work_platform/wechat_work_platform_proxy
bundle config set local.easy_style /home/andersen/Work/my_products/frontend/easy_style_engine
bundle config set local.anonymous_authorization /home/andersen/Work/my_products/auth/anonymous_authorization
bundle config set local.user_auth /home/andersen/Work/my_products/auth/user_auth
bundle config set local.tenant_auth /home/andersen/Work/my_products/auth/tenant_auth
bundle config set local.organization_auth /home/andersen/Work/my_products/auth/organization_auth
```

Then install and prepare DB:

```bash
bundle install
bin/rails db:prepare
```

Engine migrations follow engine loading behavior and should not be copied into host `db/migrate`.

## Config
- Copy/adjust `config/local_env.yml` (already created from example).
- Fill Feishu and DocuSign keys.

## Current Modules
- Tenant-scoped contract APIs: `/t/:tenant_uid/*`
- DocuSign connection API: `/t/:tenant_uid/docusign_connection`
- DocuSign webhook: `POST /webhooks/docusign`
- Feishu callback/events:
  - `GET /integrations/feishu/callback`
  - `POST /integrations/feishu/events`

## Auditing
- Model-change auditing via `audited` gem.
- Business-event audit table: `audit_logs`.
- Inbound webhook inbox table: `webhook_events` (idempotency, status, retries, payload).
- Webhook processing also logs to `Rails.logger` for plain-text trace.

## Deployment
- Deployment uses Capistrano (same pattern as `easy_biz_host_app`).
- Docker/Kamal artifacts are removed from this project.
- Configure:
  - `config/deploy.rb`
  - `config/deploy/local.rb`
  - `config/deploy/staging.rb`
  - `config/deploy/production.rb`
- Replace placeholder `repo_url`, domain, and server entries before first deploy.

## 后台搜索边界

Ransack 采用 `~> 6.0`、`>= 6.0.1`。合同／已发送文件、合同模板、签署人、Webhook 事件在各自模型显式维护可筛选字段，保留现有关键字、状态、来源、邮箱等查询。`ApplicationRecord` 不提供全字段或全关联搜索；OAuth 连接凭据、Webhook 原始 payload 和未声明的关联不开放查询。新增筛选时同步调整所属模型白名单与请求测试。
