class HomeController < ApplicationController
  def index
    redirect_to new_job_application_path if user_signed_in?
  end
end 