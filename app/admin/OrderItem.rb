ActiveAdmin.register OrderItem do
  permit_params :order_id, :product_id, :variant_id, :quantity, :unit_price, :total_price, :tax_rate, :tax_amount

  index do
    selectable_column
    id_column
    column :order do |item|
      link_to item.order.order_number, admin_order_path(item.order)
    end
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
    column :tax_rate
    column :tax_amount
    actions
  end

  show do
    attributes_table do
      row :id
      row :order do |item|
        link_to item.order.order_number, admin_order_path(item.order)
      end
      row :product do |item|
        link_to item.product.name, admin_product_path(item.product)
      end
      row :variant do |item|
        item.variant_details
      end
      row :quantity
      row :unit_price do |item|
        number_to_currency(item.unit_price, unit: "₹", format: "%u %n", precision: 2)
      end
      row :total_price do |item|
        number_to_currency(item.total_price, unit: "₹", format: "%u %n", precision: 2)
      end
      row :product_name
      row :variant_details
      row :tax_rate
      row :tax_amount
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs "Order Item Details" do
      f.input :order, as: :select, collection: Order.all.map { |o| [o.order_number, o.id] }
      f.input :product, as: :select, collection: Product.all.map { |p| [p.name, p.id] }
      f.input :variant, as: :select, collection: Variant.all.map { |v| ["#{v.product.name} - #{v.sku}", v.id] }
      f.input :quantity
      f.input :unit_price
      f.input :total_price
      f.input :tax_rate
      f.input :tax_amount
    end
    f.actions
  end

  filter :order, as: :select, collection: -> { Order.all.map { |o| [o.order_number, o.id] } }
  filter :product, as: :select, collection: -> { Product.all.map { |p| [p.name, p.id] } }
  filter :quantity
  filter :created_at
end

