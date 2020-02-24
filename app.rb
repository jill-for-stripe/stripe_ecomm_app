require 'sinatra'
require 'sinatra/reloader'
require 'stripe'
require 'json'
require 'money'

require_relative 'models/album'
require_relative 'helpers.rb'

class Application < Sinatra::Base
  
  def initialize
    @products = create_album_hash(parse_products)
    @@cart = Hash.new(0)
    @@subtotal = Money.new(0, "USD")
    @@session_id = nil
    super
  end

  # set Stripe API key
  Stripe.api_key = 'sk_test_o20UzauzBU7uIE2G7CoaMA3q00T3v4QoUU'

  # success & cancel URL's passed to Session. 
  # currently under localhost on port 9292 - would be edited here if not running locally or on a different port
  success_url = 'http://localhost:9292/success?session_id={CHECKOUT_SESSION_ID}'
  cancel_url = 'http://localhost:9292/cart'


  get '/' do 
  	erb :index, :locals => {:products => @products}
  end

  get '/cart' do
  	erb :cart, :locals => {:cart => @@cart, :products => @products, :subtotal => @@subtotal.cents / 100}
  end

  get '/checkout' do
  	session = create_stripe_session(@products, @@cart, success_url, cancel_url)
    @@session_id = session["id"]
  	erb :checkout, :locals => {:session_id => @@session_id}
  end

  get '/success' do
    @@cart.clear
    saved_subtotal = @@subtotal
    @@subtotal = Money.new(0, "USD")
  	erb :success, :locals => {:charge_id => get_charge_id(@@session_id), :subtotal => saved_subtotal.cents / 100}
  end


  post '/addToCart' do
      @@cart[params[:product_id]] += 1
      @@subtotal += Money.new(@products[params[:product_id]].price.to_i * 100, "USD")
      redirect '/'
  end

  post '/removeFromCart' do
      @@cart[params[:product_id]] -= 1
      @@subtotal -= Money.new(@products[params[:product_id]].price.to_i * 100, "USD")
      @@cart.delete(params[:product_id]) if @@cart[params[:product_id]] < 1
      redirect '/cart'
  end

  post '/goToCart' do
      redirect '/cart'
  end

  post '/goToCheckout' do
      redirect '/checkout'
  end

  helpers do
    include Helpers
  end

end
