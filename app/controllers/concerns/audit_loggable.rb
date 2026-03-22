module AuditLoggable
  extend ActiveSupport::Concern

  included do
    after_action :flush_audit_logs
  end

  private

    def audit(action:, target: nil, data: {}, tenant: current_audit_tenant, actor: current_audit_user)
      pending_audit_logs << {
        tenant: tenant,
        actor: actor,
        action: action,
        target: target,
        data: data || {}
      }
    end

    def flush_audit_logs
      return if pending_audit_logs.empty?

      pending_audit_logs.each do |entry|
        audit_log = AuditLog.create(
          tenant: entry[:tenant],
          actor_type: entry[:actor]&.class&.name,
          actor_id: entry[:actor]&.id,
          action: entry[:action],
          target_type: entry[:target]&.class&.name,
          target_id: entry[:target]&.id,
          request_id: request.request_id,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          data: entry[:data]
        )

        next if audit_log.persisted?

        Rails.logger.error(
          "[AuditLoggable] failed action=#{entry[:action]} errors=#{audit_log.errors.full_messages.to_sentence}"
        )
      rescue StandardError => e
        Rails.logger.error("[AuditLoggable] failed action=#{entry[:action]} error=#{e.class}: #{e.message}")
      end
    ensure
      pending_audit_logs.clear
    end

    def pending_audit_logs
      @pending_audit_logs ||= []
    end

    def current_audit_tenant
      current_tenant if respond_to?(:current_tenant, true)
    end

    def current_audit_user
      nil
    end
end
