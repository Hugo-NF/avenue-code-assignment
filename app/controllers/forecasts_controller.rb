class ForecastsController < ApplicationController
  def index
    render inertia: "Forecasts/Index", props: {
      address: session[:address]
    }
  end

  def create
    address = params[:address].to_s.strip

    if address.blank?
      redirect_to root_path, inertia: { errors: { address: "can't be blank" } }
      return
    end

    session[:address] = address
    redirect_to root_path
  end
end
