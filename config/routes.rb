Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :v1 do
    post 'login' => 'login#index'
    post 'firma_electronica' => 'firma_electronica#index'
  end 

  match "/404" => "aplication#error404", via: [ :get, :post, :patch, :delete ]
end
