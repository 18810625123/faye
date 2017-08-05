Rails.application.routes.draw do

  resources :channels
  get 'welcome/index'

  mount HelloApi, at: '/'

  root 'welcome#index'
end
