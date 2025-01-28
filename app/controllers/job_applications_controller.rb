class JobApplicationsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @job_applications = current_user.job_applications.order(created_at: :desc)
  end

  def new
    @job_application = JobApplication.new
  end

  def create
    @job_application = current_user.job_applications.build(job_application_params)
    
    if @job_application.save
      CustomizeResumeJob.perform_later(@job_application.id)
      redirect_to job_applications_path, notice: 'Resume customization has started!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @job_application = current_user.job_applications.find(params[:id])
  end

  private

  def job_application_params
    params.require(:job_application).permit(:job_url, :original_resume)
  end
end 