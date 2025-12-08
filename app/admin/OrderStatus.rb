ActiveAdmin.register OrderStatus do
  permit_params :order_id, :status, :notes, :created_by_id

  index do
    selectable_column
    id_column
    column :order do |status|
      link_to status.order.order_number, admin_order_path(status.order)
    end
    column :status do |status|
      status_tag status.status, class: status.status
    end
    column :notes
    column :created_by do |status|
      status.created_by.full_name
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :order do |status|
        link_to status.order.order_number, admin_order_path(status.order)
      end
      row :status do |status|
        status_tag status.status, class: status.status
      end
      row :notes
      row :created_by do |status|
        link_to status.created_by.full_name, admin_account_path(status.created_by)
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs "Order Status Details" do
      f.input :order, as: :select, collection: Order.all.map { |o| [o.order_number, o.id] }
      f.input :status, as: :select, collection: Order.statuses.keys.map { |s| [s.humanize, s] }
      f.input :notes, as: :text
      f.input :created_by, as: :select, collection: Account.all.map { |a| [a.full_name, a.id] }
    end
    f.actions
  end

  filter :order, as: :select, collection: -> { Order.all.map { |o| [o.order_number, o.id] } }
  filter :status, as: :select, collection: -> { Order.statuses.keys.map { |s| [s.humanize, s] } }
  filter :created_by, as: :select, collection: -> { Account.all.map { |a| [a.full_name, a.id] } }
  filter :created_at

  scope :all, default: true
  Order.statuses.keys.each do |s|
    scope s, -> { where(status: s) }
  end
end
