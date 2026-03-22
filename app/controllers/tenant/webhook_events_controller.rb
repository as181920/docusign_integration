module Tenant
  class WebhookEventsController < BaseController
    before_action :set_webhook_event, only: :show

    def index
      base_scope = policy_scope_records(webhook_event_scope)
      @q = base_scope.ransack(params[:q])
      @webhook_events = @q.result.page(params[:page]).per(pagination_per(default: 20))

      @recent_days = recent_days_param
      @recent_count = @q.result.where("COALESCE(received_at, created_at) >= ?", @recent_days.days.ago).count

      respond_to do |format|
        format.html
        format.json { render json: @webhook_events.as_json }
      end
    end

    def show
      @headers_json = pretty_json(@webhook_event.headers)
      @payload_json = pretty_json(@webhook_event.payload)

      respond_to do |format|
        format.html
        format.json { render json: @webhook_event.as_json }
      end
    end

    private

      def webhook_event_scope
        WebhookEvent.where(tenant: current_tenant).order(created_at: :desc, id: :desc)
      end

      def set_webhook_event
        @webhook_event = webhook_event_scope.find(params[:id])
      end

      def recent_days_param
        days = params[:recent_days].to_i
        return 7 if days <= 0

        [1, 7, 30, 90].include?(days) ? days : 7
      end

      def pretty_json(value)
        JSON.pretty_generate(value.presence || {})
      rescue JSON::GeneratorError, TypeError
        value.to_json
      end
  end
end
