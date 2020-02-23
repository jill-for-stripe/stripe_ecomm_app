require 'sinatra'
require 'sinatra/reloader'
require 'stripe'
require 'json'
require 'money'

require_relative 'models/album'
require_relative 'helpers.rb'

# global hash representation of the available products, where the product ID is the key and an Album is the value
$products = Hash.new

# global hash representation of the cart, where the product ID is the key and the quantity is the value
$cart = Hash.new(0)

# global variable to store the charge object once succeeded 
$charge = nil

# global variable to store the session id once the session is created
$session_id = nil

# subtotal of items in the cart
$subtotal = Money.new(0, "USD")

# set Stripe API key
Stripe.api_key = 'sk_test_o20UzauzBU7uIE2G7CoaMA3q00T3v4QoUU'

# success & cancel URL's passed to Session. Currently under localhost on port 4567 - would be edited here if not running locally
$success_url = 'http://localhost:4567/success?session_id={CHECKOUT_SESSION_ID}'
$cancel_url = 'http://localhost:4567/cart'


get '/' do 
	$products = create_album_hash(parse_products)
	erb :index, :locals => {:products => $products}
end

get '/cart' do
	erb :cart, :locals => {:cart => $cart, :products => $products, :subtotal => $subtotal.cents / 100}
end

get '/checkout' do
	session = create_stripe_session
  $session_id = session["id"]
	erb :checkout, :locals => {:session_id => $session_id}
end

get '/success' do
  charge_id = get_charge_id
	erb :success, :locals => {:charge_id => charge_id, :subtotal => $subtotal.cents / 100}
end


post '/addToCart' do
    $cart[params[:product_id]] += 1
    $subtotal += Money.new($products[params[:product_id]].price.to_i * 100, "USD")
    redirect '/'
end

post '/removeFromCart' do
    $cart[params[:product_id]] -= 1
    $subtotal -= Money.new($products[params[:product_id]].price.to_i * 100, "USD")
    $cart.delete(params[:product_id]) if $cart[params[:product_id]] < 1
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
