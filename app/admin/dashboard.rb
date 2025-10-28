# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # Statistics Overview Cards
    columns do
      column do
        panel "Revenue Statistics" do
          columns do
            column do
              h2 "Total Revenue", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "₹#{number_with_delimiter(Order.where(status: [:delivered, :shipped]).sum(:total_amount), delimiter: ',')}", 
                 style: "margin: 10px 0; color: #4CAF50;"
              para "From #{Order.where(status: [:delivered, :shipped]).count} completed orders"
            end
            column do
              h2 "This Month", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "₹#{number_with_delimiter(Order.where(status: [:delivered, :shipped]).where('created_at >= ?', Date.today.beginning_of_month).sum(:total_amount), delimiter: ',')}", 
                 style: "margin: 10px 0; color: #2196F3;"
              para "#{Order.where('created_at >= ?', Date.today.beginning_of_month).count} orders"
            end
            column do
              h2 "Average Order Value", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              avg_value = Order.where(status: [:delivered, :shipped]).average(:total_amount) || 0
              h3 "₹#{number_with_delimiter(avg_value.to_i, delimiter: ',')}", 
                 style: "margin: 10px 0; color: #FF9800;"
              para "Per completed order"
            end
            column do
              h2 "Total Orders", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "#{Order.count}", style: "margin: 10px 0; color: #9C27B0;"
              para "All time"
            end
          end
        end
      end
    end

    # Order Status Cards
    columns do
      column do
        panel "Order Status Overview" do
          columns do
            column do
              div style: "text-align: center; padding: 20px; background: #e3f2fd; border-radius: 8px; margin: 5px;" do
                h1 Order.where(status: 'delivered').count, style: "color: #1976D2; font-size: 3em; margin: 0;"
                para "Delivered", style: "margin: 5px 0; font-weight: bold; font-size: 1.1em;"
              end
            end
            column do
              div style: "text-align: center; padding: 20px; background: #fff3e0; border-radius: 8px; margin: 5px;" do
                h1 Order.where(status: ['confirmed', 'processing', 'shipped', 'out_for_delivery']).count, 
                   style: "color: #E65100; font-size: 3em; margin: 0;"
                para "In Progress", style: "margin: 5px 0; font-weight: bold; font-size: 1.1em;"
              end
            end
            column do
              div style: "text-align: center; padding: 20px; background: #f3e5f5; border-radius: 8px; margin: 5px;" do
                h1 Order.where(status: 'pending').count, 
                   style: "color: #7B1FA2; font-size: 3em; margin: 0;"
                para "Pending", style: "margin: 5px 0; font-weight: bold; font-size: 1.1em;"
              end
            end
            column do
              div style: "text-align: center; padding: 20px; background: #ffebee; border-radius: 8px; margin: 5px;" do
                h1 Order.where(status: ['cancelled', 'returned', 'refunded']).count, 
                   style: "color: #C62828; font-size: 3em; margin: 0;"
                para "Cancelled/Returned", style: "margin: 5px 0; font-weight: bold; font-size: 1.1em;"
              end
            end
          end
        end
      end
    end

    # Revenue Chart - Last 7 Days
    columns do
      column do
        panel "Revenue Trend - Last 7 Days" do
          revenue_data = (6.days.ago.to_date..Date.today).map do |date|
            [
              date.strftime('%b %d'),
              Order.where(status: [:delivered, :shipped])
                  .where(created_at: date.all_day)
                  .sum(:total_amount)
                  .to_f
            ]
          end.to_h

          div style: "height: 300px;" do
            line_chart revenue_data,
              height: "300px",
              colors: ["#2196F3"],
              points: true,
              xtitle: "Date",
              ytitle: "Revenue (₹)",
              library: {
                tension: 0.2,
                plugins: {
                  tooltip: {
                    callbacks: {
                      label: "function(context){ return '₹' + (context.parsed.y || 0).toLocaleString(); }"
                    }
                  }
                },
                scales: {
                  y: { beginAtZero: true }
                }
              }
          end
        end
      end
    end

    # Market Analysis - Top Products
    columns do
      column do
        panel "Top Selling Products" do
          top_products = Product.joins(:order_items)
                               .group('products.id, products.name')
                               .select('products.name, SUM(order_items.quantity) as total_quantity, COUNT(DISTINCT order_items.order_id) as order_count')
                               .order('total_quantity DESC')
                               .limit(10)
          
          table_for top_products do
            column "Product Name" do |p|
              p.name
            end
            column "Total Sold" do |p|
              p.total_quantity
            end
            column "Number of Orders" do |p|
              p.order_count
            end
          end
        end
      end
      
      column do
        panel "Sales by Category" do
          category_stats = Category.joins(subcategories: { products: { order_items: :order } })
                                  .where(orders: { status: [:delivered, :shipped] })
                                  .group('categories.name')
                                  .select('categories.name, SUM(order_items.quantity) as total_sold, SUM(order_items.total_price) as revenue')
                                  .order('revenue DESC')
          
          category_stats.each do |cat|
            div style: "margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 4px;" do
              h4 cat.name, style: "margin: 0 0 5px 0;"
              para "Sold: #{cat.total_sold} items | Revenue: ₹#{number_with_delimiter(cat.revenue.to_i)}", 
                   style: "margin: 0; color: #666;"
            end
          end
        end
      end
    end

    # Recent Orders
    columns do
      column do
        panel "Recent Orders", class: "recent_orders" do
          table_for Order.order(created_at: :desc).limit(10), class: "table" do
            column("Order") { |order| link_to order.order_number, admin_order_path(order) }
            column("Customer") { |order| order.account.full_name }
            column("Status") { |order| status_tag order.status, class: order.status }
            column("Amount") { |order| number_to_currency(order.total_amount, unit: "₹", format: "%u %n") }
            column("Date") { |order| order.created_at.strftime("%b %d, %Y") }
          end
        end
      end
    end

    columns do
      column do
        panel "Quick Stats" do
          columns do
            column do
              h2 "Total Customers", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "#{Account.count}", style: "margin: 10px 0; color: #4CAF50;"
            end
            column do
              h2 "Active Products", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "#{Product.active.count}", style: "margin: 10px 0; color: #2196F3;"
            end
            column do
              h2 "Categories", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "#{Category.count}", style: "margin: 10px 0; color: #FF9800;"
            end
            column do
              h2 "Sub Categories", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "#{Subcategory.count}", style: "margin: 10px 0; color: #FF9800;"
            end
            column do
              h2 "Subscribers", style: "margin: 0; font-size: 1.5em; font-weight: bold;"
              h3 "#{Subscribe.count}", style: "margin: 10px 0; color: #9C27B0;"
            end
          end
        end
      end
    end

    # Monthly Revenue Chart
    columns do
      column do
        panel "Monthly Revenue - Last 6 Months" do
          months = (5.months.ago.to_date.beginning_of_month..Date.today.beginning_of_month)
                      .select { |d| d.day == 1 }

          revenue_data = months.map do |date|
            [
              date.strftime('%b %Y'),
              Order.where(status: [:delivered, :shipped])
                  .where(created_at: date.all_month)
                  .sum(:total_amount)
                  .to_f
            ]
          end.to_h

          div style: "height: 300px;" do
            bar_chart revenue_data,
              height: "300px",
              colors: ["#4CAF50"], # Green
              xtitle: "Month",
              ytitle: "Revenue (₹)",
              library: {
                scales: {
                  y: { beginAtZero: true }
                },
                plugins: {
                  tooltip: {
                    callbacks: {
                      label: "function(context){ return '₹' + (context.parsed.y || 0).toLocaleString(); }"
                    }
                  }
                }
              }
          end
        end
      end
    end

  end # content
end
