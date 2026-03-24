require "base64"

module Docusign
  class TemplatePublisher
    class << self
      def call(template:)
        connection = TenantDocusignConnection.find_by!(tenant: template.tenant, status: :active)
        validate_template!(template)

        result = Docusign::ApiClient.post(
          connection: connection,
          path: "/templates",
          body: build_payload(template)
        )

        template.update!(
          docusign_template_id: result["templateId"] || result["template_id"],
          publish_state: :published,
          published_at: Time.current,
          metadata: template.metadata.to_h.merge(
            "template_source" => "local_published",
            "docusign_template_publish" => {
              "template_id" => result["templateId"] || result["template_id"],
              "published_at" => Time.current.iso8601
            }
          )
        )

        result
      end

      private

        def validate_template!(template)
          raise Docusign::Error, "template requires at least one document" if template.documents.none?
          raise Docusign::Error, "template requires at least one recipient role" if template.template_roles.none?
          raise Docusign::Error, "template requires at least one signer role" if template.template_roles.signer.none?
        end

        def build_payload(template)
          {
            name: template.name,
            description: template.description,
            emailSubject: template.email_subject.presence || "Please sign: #{template.name}",
            documents: build_documents(template),
            recipients: build_recipients(template),
            shared: "false"
          }
        end

        def build_documents(template)
          template.documents.order(:created_at).map.with_index(1) do |attachment, idx|
            ext = File.extname(attachment.filename.to_s).delete(".")

            {
              documentBase64: Base64.strict_encode64(attachment.download),
              name: attachment.filename.to_s,
              fileExtension: ext.presence || "pdf",
              documentId: idx.to_s
            }
          end
        end

        def build_recipients(template)
          signers = []
          carbon_copies = []

          template.template_roles.order(:routing_order, :id).each_with_index do |role, idx|
            recipient = {
              roleName: role.role_name,
              name: role.signer_name,
              email: role.signer_email,
              recipientId: (idx + 1).to_s,
              routingOrder: role.routing_order.to_s
            }.compact

            if role.signer?
              signers << recipient
            else
              carbon_copies << recipient
            end
          end

          recipients = { signers: signers }
          recipients[:carbonCopies] = carbon_copies if carbon_copies.any?
          recipients
        end
    end
  end
end
