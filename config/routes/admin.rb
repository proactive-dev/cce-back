namespace :admin do
  get '/', to: 'dashboard#index', as: :dashboard

  resources :documents
  resources :id_documents,     only: [:index, :show, :update]
  resource  :currency_deposit, only: [:new, :create]
  resources :markets, only: [:index]
  resources :tickets, only: [:index, :show] do
    member do
      patch :close
    end
    resources :comments, only: [:create]
  end

  resources :members, only: [:index, :show] do
    member do
      post :active
      post :toggle
    end

    resources :two_factors, only: [:destroy]
  end

  namespace :assets do
    resources :proofs
    resources :payment_addresses
  end

  namespace :deposits do
    Deposit.descendants.each do |d|
      resources d.resource_name
    end
  end

  namespace :withdraws do
    Withdraw.descendants.each do |w|
      resources w.resource_name
    end
  end

  namespace :lending do
    resources :loans, :only => [:index, :destroy]
    resource :history, :controller => 'history', :only => :show
  end

  namespace :statistic do
    resource :members, :only => :show
    resource :orders, :only => :show
    resource :trades, :only => :show
    resource :deposits, :only => :show
    resource :withdraws, :only => :show
  end
end
