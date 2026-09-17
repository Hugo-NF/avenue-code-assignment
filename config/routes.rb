Rails.application.routes.draw do
  root "forecasts#index"
  post "/", to: "forecasts#create"

  get "up" => "rails/health#show", as: :rails_health_check
end
