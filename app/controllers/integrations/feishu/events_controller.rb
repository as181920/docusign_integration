module Integrations
  module Feishu
    class EventsController < ActionController::API
      def create
        challenge = params[:challenge]
        return render json: { challenge: challenge } if challenge.present?

        AuditLog.create!(
          action: "feishu_event_received",
          request_id: request.request_id,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          data: params.to_unsafe_h
        )

        head :ok
      end
    end
  end
end
