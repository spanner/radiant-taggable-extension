class Admin::TagsController < ApplicationController
  
  make_resourceful do 
    actions :all
    after :create do
      if params[:page]
        @page = Page.find(params[:page])
        @tag.pages << @page
      end
    end
    response_for :update do |format|
      format.html { 
        flash[:notice] = "Tag updated."
        redirect_to(params[:continue] ? edit_admin_tag_url(@tag) : admin_tags_url) 
      }
    end
    response_for :create do |format|
      format.html { 
        flash[:notice] = "Tag created."
        redirect_to(@page ? page_edit_url(@page) : (params[:continue] ? edit_tag_url(@tag) : admin_tags_url)) 
      }
    end
     
  end
    
  def remove 
    @tag = Tag.find(params[:id])
    if request.post?
      @tag.destroy
      redirect_to tags_path
    end 
  end
  
end
