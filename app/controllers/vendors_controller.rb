require 'csv'
class VendorsController < ApplicationController
  load_and_authorize_resource 
  skip_load_and_authorize_resource :only => :create
  before_action :authenticate_user!
  before_action :load_vendor, except: [:index, :new, :create, :import_vendors]
  before_action :build_vendor_resource, only: :new
    
  include RestfulAction

  def index
    @offset = params[:offset] || 0
    @vendors = Vendor.vendors_sorted.skip(@offset).limit(20)
    respond_to do |format|
      format.json{ render json: @vendors.to_json}
      format.html{}
    end
  end

  def create
    @vendor = Vendor.new(safe_params)
    if @vendor.save
      redirect_to vendors_path
    else
      render :new
    end
  end
  
  def edit
    @vendor.build_address if @vendor.address.nil?
  end

  def update
    update_obj(@vendor, safe_params, vendors_path)
  end

  def destroy
    if @vendor.destroy
     flash[:notice] = "Vendor deleted Successfully"
    else
     flash[:notice] = "Error in deleting vendor"
    end
     redirect_to vendors_path
  end

  def import_vendors
    @message = { type: :notice, message: "Vendors added successfully from CSV" }
    parse_csv_file(params[:csv_file])
    flash[@message[:type]] = @message[:message]
    redirect_to vendors_path 
  end
  
  private
  
  def parse_csv_file(csv)
    CSV.foreach(csv.tempfile) do |row|
      next if $. == 1
      check_csv_row(row)
    end
  end
  
  def check_csv_row(row)
    if row.length != 7
      @message = { type: :error, message: "Error in csv file" }
      return
    else
      Vendor.process_vendors_csv_file(row)
    end
  end

  def safe_params
    params.require(:vendor).permit(:company, :category, contact_persons_attributes: [:id, :name, :role, :phone_no, :email], 
                                   address_attributes: [:id, :address, :city, :pin_code, :state, :landline_no ])     
  end
  
  def load_vendor
    @vendor = Vendor.find(params[:id])
  end

  def build_vendor_resource
    @vendor = Vendor.new
    @vendor.contact_persons.build if @vendor.contact_persons.empty?
    @vendor.build_address if @vendor.address.nil?
  end
end
