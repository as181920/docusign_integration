require "uri"

module Docusign
  class TemplateSyncService
    DEFAULT_PAGE_SIZE = 100
    DEFAULT_MAX_PAGES = 10

    class << self
      def call(tenant:, connection: nil, page_size: DEFAULT_PAGE_SIZE, max_pages: DEFAULT_MAX_PAGES)
        active_connection = connection || TenantDocusignConnection.find_by!(tenant: tenant, status: :active)
        templates = fetch_templates(connection: active_connection, page_size: page_size, max_pages: max_pages)
        persisted_summary = persist_templates(tenant: tenant, templates: templates)

        persisted_summary.merge(total_count: templates.size)
      end

      private

        def fetch_templates(connection:, page_size:, max_pages:)
          path = "/templates?count=#{page_size}"
          templates = []
          page = 0

          while path.present? && page < max_pages
            page += 1
            response = Docusign::ApiClient.get(connection: connection, path: path)
            templates.concat(extract_templates(response))
            path = normalize_next_path(response["nextUri"] || response["next_uri"], account_id: connection.docusign_account_id)
          end

          templates
        end

        def extract_templates(response)
          candidates = [
            response["envelopeTemplates"],
            response["envelopeTemplateResults"],
            response["templateResults"],
            response["templates"],
            response["items"],
            response["results"],
            response.dig("templateList", "envelopeTemplates")
          ]

          selected = candidates.compact.find { |value| value.is_a?(Array) && value.any? }
          return selected if selected.present?

          response.values.find { |value| template_collection?(value) } || []
        end

        def template_collection?(value)
          return false unless value.is_a?(Array)

          value.any? { |item| template_payload_present?(item) }
        end

        def template_payload_present?(item)
          return false unless item.is_a?(Hash)

          payload = template_payload_for(item)
          payload["templateId"].present? || payload["template_id"].present?
        end

        def normalize_next_path(next_uri, account_id:)
          return nil if next_uri.blank?

          uri = URI.parse(next_uri)
          path = uri.path.to_s
          query = uri.query.to_s
          full_path = query.present? ? "#{path}?#{query}" : path

          account_prefixes = [
            "/v2.1/accounts/#{account_id}",
            "/accounts/#{account_id}"
          ]

          account_prefixes.each do |prefix|
            return full_path.delete_prefix(prefix) if full_path.start_with?(prefix)
          end

          return full_path if full_path.start_with?("/templates")

          nil
        rescue URI::InvalidURIError
          nil
        end

        def persist_templates(tenant:, templates:)
          created_count = 0
          updated_count = 0
          skipped_count = 0

          templates.each do |remote_template|
            template_id = template_id_for(remote_template)

            if template_id.blank?
              skipped_count += 1
              next
            end

            record = ContractTemplate.find_or_initialize_by(tenant: tenant, docusign_template_id: template_id)
            is_new_record = record.new_record?

            assign_template_attributes(record: record, tenant: tenant, remote_template: remote_template)
            record.save!

            if is_new_record
              created_count += 1
            else
              updated_count += 1
            end
          end

          {
            created_count: created_count,
            updated_count: updated_count,
            skipped_count: skipped_count
          }
        end

        def assign_template_attributes(record:, tenant:, remote_template:)
          remote_name = template_name_for(remote_template)
          remote_description = template_payload_for(remote_template)["description"].to_s

          managed_by_sync = record.new_record? || record.metadata.to_h["template_source"] == "docusign_sync"

          if record.new_record?
            record.name = remote_name
            record.version = next_version_for(tenant: tenant, name: remote_name)
          elsif managed_by_sync
            record.name = remote_name
          end

          record.name = remote_name if record.name.blank?
          record.version = next_version_for(tenant: tenant, name: record.name) if record.version.blank?
          record.status = "active" if record.status.blank?
          if managed_by_sync
            record.description = remote_description if remote_description.present?
          elsif record.description.blank? && remote_description.present?
            record.description = remote_description
          end

          record.metadata = record.metadata.to_h.merge(
            "template_source" => "docusign_sync",
            "docusign_template" => normalized_remote_template(remote_template),
            "docusign_synced_at" => Time.current.iso8601
          )
        end

        def template_payload_for(remote_template)
          payload = remote_template["envelopeTemplateDefinition"] || remote_template["envelope_template_definition"]
          payload.is_a?(Hash) ? payload : remote_template
        end

        def template_id_for(remote_template)
          payload = template_payload_for(remote_template)
          payload["templateId"] || payload["template_id"]
        end

        def template_name_for(remote_template)
          payload = template_payload_for(remote_template)
          value = payload["name"].to_s.strip
          return value if value.present?

          template_id = template_id_for(remote_template)
          template_id.present? ? "Template #{template_id}" : "Template"
        end

        def normalized_remote_template(remote_template)
          payload = template_payload_for(remote_template)

          {
            "template_id" => payload["templateId"] || payload["template_id"],
            "name" => payload["name"],
            "description" => payload["description"],
            "folder_name" => remote_template["folderName"] || remote_template["folder_name"],
            "shared" => payload["shared"] || remote_template["shared"],
            "last_modified" => payload["lastModified"] || payload["last_modified"] || remote_template["lastModified"] || remote_template["last_modified"]
          }.compact
        end

        def next_version_for(tenant:, name:)
          ContractTemplate.where(tenant: tenant, name: name).maximum(:version).to_i + 1
        end
    end
  end
end
