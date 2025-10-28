ActiveAdmin.register Order do
  permit_params :account_id, :shipping_address_id, :billing_address_id, :status, 
                :payment_status, :payment_method, :notes, :shipped_at, :delivered_at, :cancelled_at

  index do
    selectable_column
    id_column
    column :order_number
    column :account do |order|
      link_to order.account.full_name, admin_account_path(order.account)
    end
    tag_column :status, interactive: true
    column :payment_status do |order|
      status_tag order.payment_status, class: order.payment_status
    end
    column :total_amount do |order|
      number_to_currency(order.total_amount, unit: "₹", format: "%u %n", precision: 2)
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :order_number
      row :account do |order|
        link_to order.account.full_name, admin_account_path(order.account)
      end
      row :status do |order|
        status_tag order.status, class: order.status
      end
      row :payment_status do |order|
        status_tag order.payment_status, class: order.payment_status
      end
      row :payment_method
      row :subtotal do |order|
        number_to_currency(order.subtotal, unit: "₹", format: "%u %n", precision: 2)
      end
      row :tax_amount do |order|
        number_to_currency(order.tax_amount, unit: "₹", format: "%u %n", precision: 2)
      end
      row :shipping_amount do |order|
        number_to_currency(order.shipping_amount, unit: "₹", format: "%u %n", precision: 2)
      end
      row :discount_amount do |order|
        number_to_currency(order.discount_amount, unit: "₹", format: "%u %n", precision: 2)
      end
      row :total_amount do |order|
        number_to_currency(order.total_amount, unit: "₹", format: "%u %n", precision: 2)
      end
      row :shipping_address do |order|
        order.shipping_address_full
      end
      row :billing_address do |order|
        order.billing_address_full
      end
      row :notes
      row :shipped_at
      row :delivered_at
      row :cancelled_at
      row :created_at
      row :updated_at
    end

    panel "Order Items" do
      table_for order.order_items.includes(:product, :variant) do
        column :product do |item|
          link_to item.product.name, admin_product_path(item.product)
        end
        column :variant do |item|
          item.variant_details
        end
        column :quantity
        column :unit_price do |item|
          number_to_currency(item.unit_price, unit: "₹", format: "%u %n", precision: 2)
        end
        column :total_price do |item|
          number_to_currency(item.total_price, unit: "₹", format: "%u %n", precision: 2)
        end
      end
    end

    panel "Status History" do
      table_for order.order_statuses.recent do
        column :status do |status|
          status_tag status.status, class: status.status
        end
        column :notes
        column :created_by do |status|
          status.created_by.full_name
        end
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Order Details" do
      f.input :account, as: :select, collection: Account.all.map { |a| [a.full_name, a.id] }
      f.input :shipping_address, as: :select, collection: Address.all.map { |a| [a.full_address, a.id] }
      f.input :billing_address, as: :select, collection: Address.all.map { |a| [a.full_address, a.id] }
      f.input :status, as: :select, collection: Order.statuses.keys.map { |s| [s.humanize, s] }
      f.input :payment_status, as: :select, collection: Order.payment_statuses.keys.map { |s| [s.humanize, s] }
      f.input :payment_method, as: :select, collection: Order.payment_methods.keys.map { |m| [m.humanize, m] }
      f.input :notes, as: :text
      f.input :shipped_at, as: :datetime_picker
      f.input :delivered_at, as: :datetime_picker
      f.input :cancelled_at, as: :datetime_picker
    end
    f.actions
  end

  filter :order_number
  # Enhanced account filter; use simple select to avoid extra endpoints
  filter :account, as: :select, collection: -> { Account.all.map { |a| [a.full_name, a.id] } }
  filter :status, as: :select, collection: Order.statuses.keys.map { |s| [s.humanize, s] }
  filter :payment_status, as: :select, collection: Order.payment_statuses.keys.map { |s| [s.humanize, s] }
  filter :created_at
  filter :total_amount

  scope :all, default: true
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :processing, -> { where(status: 'processing') }
  scope :shipped, -> { where(status: 'shipped') }
  scope :out_for_delivery, -> {where(status: 'out_for_delivery')}
  scope :delivered, -> { where(status: 'delivered') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :returned, -> { where(status: 'returned') }
  scope :refunded, -> { where(status: 'refunded') }
end
