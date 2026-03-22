module Integrations
  module Feishu
    class EventsController < ActionController::API
      include AuditLoggable

      def create
        challenge = params[:challenge]
        return render json: { challenge: challenge } if challenge.present?

        audit(action: "feishu_event_received", data: params.to_unsafe_h)
        head :ok
      end
    end
  end
end
