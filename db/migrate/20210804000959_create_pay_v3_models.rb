class CreatePayV3Models < ActiveRecord::Migration[6.0]
  def change
    add_column :plans, :currency, :string
    add_column :plans, :interval_count, :integer, default: 1
    add_column :plans, :description, :string

    create_table :pay_customers do |t|
      t.belongs_to :owner, polymorphic: true, index: false, type: :uuid
      t.string :processor
      t.string :processor_id
      t.boolean :default
      t.public_send Pay::Adapter.json_column_type, :data
      t.datetime :deleted_at

      t.timestamps
    end
    # Index for `payment_processor` and `pay_customer` associations
    add_index :pay_customers, [:owner_type, :owner_id, :deleted_at], name: :customer_owner_processor_index

    # Index typically used by webhooks
    add_index :pay_customers, [:processor, :processor_id]

    create_table :pay_merchants do |t|
      t.belongs_to :owner, polymorphic: true, index: false, type: :uuid
      t.string :processor
      t.string :processor_id
      t.boolean :default
      t.public_send Pay::Adapter.json_column_type, :data

      t.timestamps
    end
    add_index :pay_merchants, [:owner_type, :owner_id, :processor]

    create_table :pay_payment_methods do |t|
      t.belongs_to :customer, foreign_key: {to_table: :pay_customers}, index: false
      t.string :processor_id
      t.boolean :default
      t.string :type
      t.public_send Pay::Adapter.json_column_type, :data

      t.timestamps
    end
    add_index :pay_payment_methods, [:customer_id, :processor_id], unique: true

    create_table :pay_webhooks do |t|
      t.string :processor
      t.string :event_type
      t.public_send Pay::Adapter.json_column_type, :event

      t.timestamps
    end

    add_column :pay_charges, :application_fee_amount, :integer
    add_column :pay_charges, :currency, :string
    add_column :pay_charges, :metadata, Pay::Adapter.json_column_type
    add_column :pay_charges, :subscription_id, :integer
    add_column :pay_subscriptions, :application_fee_percent, :decimal, precision: 8, scale: 2
    add_column :pay_subscriptions, :metadata, Pay::Adapter.json_column_type

    remove_index :pay_charges, [:processor, :processor_id] if index_exists?(:pay_charges, [:processor, :processor_id])
    remove_index :pay_subscriptions, [:processor, :processor_id] if index_exists?(:pay_subscriptions, [:processor, :processor_id])

    add_reference :pay_charges, :customer, foreign_key: {to_table: :pay_customers}, index: false
    add_reference :pay_subscriptions, :customer, foreign_key: {to_table: :pay_customers}, index: false
    add_index :pay_charges, [:customer_id, :processor_id], unique: true
    add_index :pay_subscriptions, [:customer_id, :processor_id], unique: true
  end
end
