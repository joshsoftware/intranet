module RestfulAction
  extend ActiveSupport::Concern

  def update_obj(model_obj, params, redirect_path)
    if model_obj.update_attributes(params)
      flash[:success] = "#{model_obj.class.to_s} updated Successfully"
      redirect_to redirect_path
    else
      flash[:error] = "#{model_obj.class.to_s}: #{get_detail_message(model_obj)}"
      render 'edit'
    end
  end

  def get_detail_message(model_obj)
    msgs = model_obj.errors.full_messages
    msgs = msgs.map{|i| i.gsub("User projects", "Team Detail")}
    msgs.join(',')
  end
end
