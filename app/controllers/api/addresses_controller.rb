module Api
  class AddressesController < ApplicationController
    before_action :set_account
    before_action :authenticate_request
    before_action :set_address, only: [:show, :update, :destroy]

    def index
      addresses = @account.addresses
      if addresses.exists?
        render json: {
          data: ActiveModelSerializers::SerializableResource.new(addresses, each_serializer: AddressSerializer),
          message: "Address list fetched successfully"
        }, status: :ok
      else
        render json: { errors: "No addresses found"}, status: :not_found
      end
    end

    def show
      render json: {
        data: AddressSerializer.new(@address),
        message: "Address details fetched successfully"
      }, status: :ok
    end

    def create
      address = @account.addresses.build(address_params)

      if address.is_default
        @account.addresses.update_all(is_default: false)
      end
      if address.save
        render json: {
          data: AddressSerializer.new(address),
          message: "Address added successfully"
        }, status: :created
      else
        render json: {
          errors: address.errors.full_messages,
        }, status: :unprocessable_entity
      end
    end

    def update
      if address_params[:is_default] == true || address_params[:is_default] == "true"
        @account.addresses.update_all(is_default: false)
      end
      if @address.update(address_params)
        render json: {
          data: AddressSerializer.new(@address),
          message: "Address updated successfully"
        }, status: :ok
      else
        render json: {
          errors: @address.errors.full_messages,
        }, status: :unprocessable_entity
      end
    end

    def destroy
      @address.destroy
      render json: {
        message: "Address deleted successfully",
      }, status: :ok
    end

    private

    def set_account
      @account = Account.find(params[:account_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: "Account not found", status: 404 }, status: :not_found
    end

    def set_address
      @address = @account.addresses.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: "Address not found", status: 404 }, status: :not_found
    end

    def address_params
      params.require(:address).permit(:name, :phone, :address_line1, :address_line2, :city, :state, :pincode, :country, :address_type, :is_default)
    end
  end
end
