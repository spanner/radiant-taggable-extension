class Admin::TaggingsController < Admin::ResourceController
  
  def destroy
    model.destroy
    render :nothing => true
  end

end
