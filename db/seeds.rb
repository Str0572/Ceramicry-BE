# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
AdminUser.create!(email: 'admin@ceramicry.com', password: 'password', password_confirmation: 'password')
Category.find_or_create_by!(name: 'Dinnerware', description: 'Plates, bowls, and other dinnerware items.')
Category.find_or_create_by!(name: 'Drinkware', description: 'Cups, mugs, and other drinkware items.')
Category.find_or_create_by!(name: 'Serveware', description: 'Serving dishes and platters.')
Category.find_or_create_by!(name: 'Sets', description: 'Coordinated sets of dinnerware.')