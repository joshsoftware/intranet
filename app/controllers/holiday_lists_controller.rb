class HolidayListsController < ApplicationController

  before_action :load_holiday, only: [:update, :edit, :destroy]
  attr_accessor :holiday

  def index
    @year = params[:year].present? ? params[:year].to_i : Date.today.year
    date  = Date.new(@year)
    @holidays = HolidayList.where(holiday_date: date..date.at_end_of_year).
      order(holiday_date: :asc)
  end

  def create
    @holiday = HolidayList.new(holiday_params)
    if @holiday.valid?
      @holiday.save
      flash[:success] = "Holiday Created Successfully"
      redirect_to new_holiday_list_path
    else
      render 'new'
    end
  end

  def new
    @holiday = HolidayList.new
  end

  def edit
  end

  def update
    if @holiday.update(holiday_params)
      flash[:success] = 'Holiday Updated Successfully'
      redirect_to holiday_lists_path
    end
  end

  def destroy
    if @holiday.destroy
      flash[:success] = 'Holiday Deleted Successfully'
      redirect_to holiday_lists_path
    end
  end

  def holiday_list
    date    = Date.today.at_beginning_of_year
    holiday = HolidayList.where(:holiday_date.gte => date)
    render json: holiday
  end


  private

  def holiday_params
    params.require(:holiday_list).permit(:holiday_date, :reason)
  end

  def load_holiday
    @holiday = HolidayList.find(params[:id])
  end
end
