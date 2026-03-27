class AddAppConfigToFeishuEnterprises < ActiveRecord::Migration[8.1]
  def change
    change_column_null :feishu_enterprises, :tenant_key, true

    add_column :feishu_enterprises, :app_secret, :string
    add_column :feishu_enterprises, :app_verification_token, :string
    add_column :feishu_enterprises, :app_encrypt_key, :string
  end
end
