Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "sessions#landing_page"

  # Defines the root path route ("/")
  ####### Session #############
  post 'create' => 'sessions#create'
  post 'reset_user_password' => 'sessions#reset_user_password'
  get 'logout' => 'sessions#destroy'
  get 'login' => 'sessions#login'
  get 'home' => 'sessions#landing_page'
  get 'signup' => 'sessions#sign_up'
  get 'recover' => 'sessions#recover'
  post 'send_recover' => 'sessions#send_recover_email'
  post 'set_password' => 'sessions#set_password'
  get 'change_password' => 'sessions#change_password'
  get 'reset_password' => 'sessions#reset_password'

  ########## Dashboard #########
  get 'dashboard' => 'dashboards#index'
  get 'admin' => 'dashboards#admin'
  get 'approval_request' => 'dashboards#approval_request'
  get 'cart' => 'home#cart'
  post 'checkout' => 'home#checkout'
  get 'checkout_page' => 'home#checkout_page'

  ########## Referrals #########
  resources :referrals, only: [:index] do
    member do
      get :referral_details
    end
  end
  resources :purchases do
    get 'cancel', on: :collection
    collection do
      get 'pending_approvals', to: 'purchases#pending_approvals' # Display all pending purchases
      post 'approve', to: 'purchases#approve' # Approve a purchase
      post 'reject', to: 'purchases#reject' # Approve a purchase
    end
  end
  resources :withdrawals, only: [:create,:index]
  get 'withdrawals/pending_withdrawals', to: 'withdrawals#pending_withdrawals'
  post 'withdrawals/:id/approve', to: 'withdrawals#approve', as: 'approve_withdrawal'
  post 'withdrawals/:id/reject', to: 'withdrawals#reject', as: 'reject_withdrawal'

  ##### Duration Plan #####
  get 'plan_duration' => 'plan_durations#index'
  post 'new_plan_duration' => 'plan_durations#create'
  post 'update_plan_duration' => 'plan_durations#update'
  post 'delete_plan_duration' => 'plan_durations#destroy'
  get 'plan_duration/:id/edit_modal', to: 'plan_durations#edit_modal', as: 'edit_modal_plan_duration'


  ##### deposit Plan #####
  get 'deposit' => 'deposits#index'
  post 'new_deposit' => 'deposits#create'
  post 'approve_deposit/:id' => 'deposits#approve_deposit', as: 'approve_deposit'
  post 'reject_deposit/:id' => 'deposits#reject_deposit', as: 'reject_deposit'

  ##### Investment Plan #####
  get 'investment_plan' => 'investment_plans#index'
  post 'new_investment_plan' => 'investment_plans#create'
  post 'update_investment_plan' => 'investment_plans#update'
  post 'delete_investment_plan' => 'investment_plans#destroy'
  get 'investment_plan/:id/edit_modal', to: 'investment_plans#edit_modal', as: 'edit_modal_investment_plan'
  get 'plans/investment', to: 'investment_plans#investment', as: 'investment_plans'


  ##### Bank Account #####
  get 'bank_account' => 'bank_account_details#index'
  post 'new_bank_account' => 'bank_account_details#create'
  post 'update_bank_account' => 'bank_account_details#update'
  post 'delete_bank_account' => 'bank_account_details#destroy'
  get 'bank_account/:id/edit_modal', to: 'bank_account_details#edit_modal', as: 'edit_modal_bank_account'


  ##### Rank #####
  get 'rank' => 'ranks#index'
  post 'new_rank' => 'ranks#create'
  post 'update_rank' => 'ranks#update'
  post 'delete_rank' => 'ranks#destroy'
  get 'rank/:id/edit_modal', to: 'ranks#edit_modal', as: 'edit_modal_rank'

  ##### Trading Plan #####
  get 'trading_plan' => 'trading_plans#index'
  post 'new_trading_plan' => 'trading_plans#create'
  post 'update_trading_plan' => 'trading_plans#update'
  post 'delete_trading_plan' => 'trading_plans#destroy'
  get 'trading_plan/:id/edit_modal', to: 'trading_plans#edit_modal', as: 'edit_modal_trading_plan'
  get 'plans/trading', to: 'trading_plans#trading', as: 'trading_plans'
  post '/apply_manual_profit_loss', to: 'trading_plans#apply_manual_profit_loss'

  ##### staking Plan #####
  get 'staking_plan' => 'staking#index'
  post 'new_staking_plan' => 'staking#create'
  post 'update_staking_plan' => 'staking#update'
  post 'delete_staking_plan' => 'staking#destroy'
  get 'staking/:id/edit_modal', to: 'staking#edit_modal', as: 'edit_modal_staking_plan'
  get 'staking/:id', to: 'staking#index', as: 'staking'
  get 'plans/staking', to: 'staking#staking', as: 'staking_plans'

  ##### USERS #####
  get 'user' => 'users#index'
  post 'new_user' => 'users#create'
  post 'update_user' => 'users#update'
  post 'delete_user' => 'users#destroy'
  post 'change_password_user' => 'users#change_password'
  get 'user_profile' => 'users#user_profile'
  post '/update_preference', to: 'users#update_preference'
  get 'users/:id/referral_data', to: 'users#referral_data'
  get 'users/current_profit', to: 'users#current_profit'
  post 'users/reset_rank_flag', to: 'users#reset_rank_flag', as: 'reset_rank_flag_users'

  ##### MENUS #####
  get 'menu' => 'menus#index'
  post 'new_menu' => 'menus#create'
  post 'update_menu' => 'menus#update'
  post 'delete_menu' => 'menus#destroy'
  get 'menus/:id/edit_modal', to: 'menus#edit_modal', as: 'edit_modal_menu'


  resources :packages, only: [:index, :show, :create, :update, :destroy] do
    collection do
      get 'list', to: 'packages#list', defaults: { format: :json }
      get 'active_plan', to: 'packages#active_plan', defaults: { format: :json }
      get 'pending_requests', to: 'packages#pending_requests', defaults: { format: :json }
    end
    member do
      delete 'cancel_plan', to: 'packages#cancel_plan'
      put 'approve', to: 'packages#approve'
      put 'reject', to: 'packages#reject'
    end
  end
  ##### ROLE/PERMISSIONS #####
  get 'role' => 'roles#index'
  post 'new_role' => 'roles#create'
  post 'update_role' => 'roles#update'
  post 'delete_role' => 'roles#destroy'
  get 'roles/:id/edit_modal', to: 'roles#edit_modal', as: 'edit_modal_role'

  ##### ACTIVITY STREAMS #####
  get 'activity_stream' => 'activity_streams#index'
  get 'activity_streams', to: 'activity_streams#activity_streams', defaults: { format: 'json' }
  post 'filter_activity_stream' => 'activity_streams#show'
end
