require 'sinatra'
require 'sinatra/reloader'
require 'stripe'
require 'json'

require_relative 'models/album'

# global hash representation of the available products, where the product ID is the key and an Album is the value
$products = Hash.new

# global hash representation of the cart, where the product ID is the key and the quantity is the value
$cart = Hash.new(0)

# global variable to store the charge object once succeeded 
$charge = nil

# global variable to store the session id once the session is created
$session_id = nil

# subtotal of items in the cart (stored as string)
$subtotal = "0"

# set Stripe API key
Stripe.api_key = 'sk_test_o20UzauzBU7uIE2G7CoaMA3q00T3v4QoUU'

# success & cancel URL's passed to Session. Currently under localhost on port 4567 - would be edited here if not running locally
$success_url = 'http://localhost:4567/success?session_id={CHECKOUT_SESSION_ID}'
$cancel_url = 'http://localhost:4567/cart'


# returns JSON product data from Products API resource
def parse_products
	response = JSON.parse(Stripe::Product.list().to_s)
	response["data"]
end

# converts array of JSON product data into hash of products where product ID is the key and Album object is the value
def create_album_hash(products_array)
	album_hash = {}
	products_array.each do |product| 
		album = Album.new(product["name"], product["metadata"]["price"], product["images"][0])
		album_hash[product["id"]] = album
	end
	album_hash
end

# creates session to pass id to redirectToCheckout for Checkout functionality
def create_stripe_session
	items=[]
	$cart.each do |product_id, quantity|
  		item = {}
  		item["amount"] = $products[product_id].price.to_i * 100
  		item["currency"] = 'usd'
  		item["name"] = $products[product_id].name
  		item["quantity"] = quantity
  		items.push(item)
  	end
	session = Stripe::Checkout::Session.create(
  	payment_method_types: ['card'],
  	line_items: items,
  	success_url: $success_url,
  	cancel_url: $cancel_url
)
end	

#function to get 5 most recent charges and look to match to session on payment intent. NOTE: see README to see how I would use webhooks instead
def get_charge_id  
  charge_id = nil
  if $session_id != nil
    session = Stripe::Checkout::Session.retrieve($session_id)
    charge_list = Stripe::Charge.list({limit: 5})
    charge_list["data"].each do |charge|
      if charge["payment_intent"] == session["payment_intent"] && charge["status"] == "succeeded"
        charge_id = charge["id"]
        break
      end
    end
  end
  puts "charge_id not found" if charge_id == nil
  charge_id
end

get '/' do 
	$products = create_album_hash(parse_products)
	erb :index, :locals => {:products => $products}
end

get '/cart' do
	erb :cart, :locals => {:cart => $cart, :products => $products, :subtotal => $subtotal}
end

get '/checkout' do
	session = create_stripe_session
  $session_id = session["id"]
	erb :checkout, :locals => {:session_id => $session_id}
end

get '/success' do
  charge_id = get_charge_id
	erb :success, :locals => {:charge_id => charge_id, :subtotal => $subtotal}
end


post '/addToCart' do
    $cart[params[:product_id]] += 1
    newsub = $subtotal.to_i + $products[params[:product_id]].price.to_i
    $subtotal = newsub.to_s
    redirect '/'
end

post '/removeFromCart' do
    $cart[params[:product_id]] -= 1
    newsub = $subtotal.to_i - $products[params[:product_id]].price.to_i
    $subtotal = newsub.to_s
    $cart.delete(params[:product_id]) if $cart[params[:product_id]] < 1
    redirect '/cart'
end

post '/goToCart' do
    redirect '/cart'
end

post '/goToCheckout' do
    redirect '/checkout'
end
