class HolidayListsController < ApplicationController
  before_action :load_holiday, except: [:index, :create, :new]
  
  def new
    @holiday = HolidayList.new
    render '_add_holiday'
  end

  def create
    @create_holiday = HolidayList.new(permitted_params)
    if @create_holiday.valid?
      @create_holiday.save
      flash[:notice] = "Holiday Added Succesfully"
      redirect_to new_holiday_list_path
    else
      flash[:error] = "Same Holiday cannot be add Or Date and Reason for Holiday is compulsory"
      redirect_to new_holiday_list_path
    end
  end

  def update
    if @holiday.update(permitted_params)
      redirect_to holiday_lists_path
    else
      render '_add_holiday' 
    end
  end

  def edit
    render '_add_holiday'
  end

  def destroy
    flash[:notice] = @holiday.destroy ? "Holiday removed Succesfully" : "Error in deleting holiday"
    redirect_to holiday_lists_path
  end
  
  def index
    @all_holidays = HolidayList.all.order_by(holiday_date: :asc)
    @a = Time.current.year
  end

  private
    def load_holiday
      @holiday = HolidayList.find(params[:id])
    end


    def permitted_params
      #params.require(:holiday_list).permit(:holiday_list, :holiday_date, :reason)
      params.require(:holiday_list).permit(:holiday_date, :reason)
    end
end
