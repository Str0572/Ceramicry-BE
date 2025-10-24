ActiveAdmin.register Offer do
  permit_params :code, :discount, :discount_type, :min_order, :description, :active, :expires_at, :usage_limit

  index do
    selectable_column
    id_column
    column :code
    column :discount
    column :discount_type
    column :min_order
    column :usage_limit
    column("Used") { |offer| offer.offer_usages.count }
    column("Remaining") { |offer| offer.usage_limit.zero? ? "∞" : offer.usage_limit - offer.offer_usages.count }
    column :expires_at
    column :active
    column :created_at
    actions
  end

  form do |f|
    f.inputs "Offer Details" do
      f.input :code
      f.input :discount
      f.input :discount_type, as: :select
      f.input :min_order
      f.input :description
      f.input :usage_limit, hint: "0 means unlimited"
      f.input :expires_at, as: :datetime_picker
      f.input :active
    end
    f.actions
  end

  show do
    attributes_table do
      row :code
      row :discount
      row :discount_type
      row :min_order
      row :description
      row :usage_limit
      row :expires_at
      row :active
      row("Used") { |offer| offer.offer_usages.count }
      row("Remaining") { |offer| offer.usage_limit.zero? ? "∞" : offer.usage_limit - offer.offer_usages.count }
      row("Used By") { |offer| offer.accounts.pluck(:full_name).join(", ") }
    end
  end
end
