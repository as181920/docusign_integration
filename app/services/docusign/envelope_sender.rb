require "base64"

module Docusign
  class EnvelopeSender
    class << self
      def call(contract:)
        connection = TenantDocusignConnection.find_by!(tenant: contract.tenant, status: :active)
        validate_contract(contract)

        payload = build_payload(contract)
        result = Docusign::ApiClient.post(connection: connection, path: "/envelopes", body: payload)

        envelope = ContractEnvelope.find_or_initialize_by(contract:)
        envelope_status = normalize_envelope_status(result["status"])

        envelope.tenant_docusign_connection = connection
        envelope.envelope_id = result.fetch("envelopeId")
        envelope.status = envelope_status
        envelope.sent_at ||= Time.current if envelope_status == "sent"
        envelope.completed_at ||= Time.current if envelope_status == "completed"
        envelope.metadata = envelope.metadata.to_h.merge(result)
        envelope.save!

        update_contract_status(contract, envelope_status)
        envelope
      end

      private

        def validate_contract(contract)
          raise Docusign::Error, "contract requires at least one signer" if contract.contract_signers.signer.none?

          if contract.docusign_template_id.blank? && contract.documents.none?
            raise Docusign::Error, "contract requires at least one document or docusign_template_id"
          end
        end

        def update_contract_status(contract, envelope_status)
          attrs = {}
          attrs[:status] = envelope_status if Contract.statuses.key?(envelope_status)
          attrs[:sent_at] = Time.current if envelope_status == "sent" && contract.sent_at.blank?
          attrs[:completed_at] = Time.current if envelope_status == "completed" && contract.completed_at.blank?
          contract.update!(attrs) if attrs.any?
        end

        def normalize_envelope_status(raw_status)
          status = raw_status.to_s.downcase
          return status if ContractEnvelope.statuses.key?(status)

          "sent"
        end

        def build_payload(contract)
          if contract.docusign_template_id.present?
            {
              templateId: contract.docusign_template_id,
              templateRoles: build_template_roles(contract),
              status: "sent"
            }
          else
            build_document_payload(contract)
          end
        end

        def build_template_roles(contract)
          contract.contract_signers.order(:routing_order, :id).map.with_index(1) do |signer, idx|
            role = {
              email: signer.email,
              name: signer.name,
              roleName: signer.role_name,
              routingOrder: signer.routing_order.to_s,
              recipientId: idx.to_s
            }

            if signer.signer?
              role[:clientUserId] = Docusign::RecipientIdentity.client_user_id(signer)
              role[:embeddedRecipientStartURL] = "SIGN_AT_DOCUSIGN"
            end

            role
          end
        end

        def build_document_payload(contract)
          {
            emailSubject: "Please sign contract: #{contract.title}",
            documents: build_documents(contract),
            recipients: build_recipients(contract),
            status: "sent"
          }
        end

        def build_documents(contract)
          contract.documents.order(:created_at).map.with_index(1) do |attachment, idx|
            ext = File.extname(attachment.filename.to_s).delete(".")
            {
              documentBase64: Base64.strict_encode64(attachment.download),
              name: attachment.filename.to_s,
              fileExtension: ext.presence || "pdf",
              documentId: idx.to_s
            }
          end
        end

        def build_recipients(contract)
          signers = []
          carbon_copies = []

          contract.contract_signers.order(:routing_order, :id).each_with_index do |signer, idx|
            recipient_id = (idx + 1).to_s
            base_attrs = {
              email: signer.email,
              name: signer.name,
              recipientId: recipient_id,
              routingOrder: signer.routing_order.to_s
            }

            if signer.signer?
              signers << base_attrs.merge(
                clientUserId: Docusign::RecipientIdentity.client_user_id(signer),
                embeddedRecipientStartURL: "SIGN_AT_DOCUSIGN",
                tabs: {
                  signHereTabs: [
                    {
                      documentId: "1",
                      pageNumber: "1",
                      xPosition: "100",
                      yPosition: (140 + idx * 70).to_s
                    }
                  ]
                }
              )
            else
              carbon_copies << base_attrs
            end
          end

          recipients = { signers: signers }
          recipients[:carbonCopies] = carbon_copies if carbon_copies.any?
          recipients
        end
    end
  end
end
