module Helpers
  # returns JSON product data from Products API resource
  def parse_products
    response = JSON.parse(Stripe::Product.list().to_s)
    response["data"]
  end

  # converts array of JSON product data into hash of products where product ID is the key and Album object is the value
  def create_album_hash(products)
    album_hash = {}
    products.each do |product| 
      album = Album.new(product["name"], product["metadata"]["price"], product["images"][0])
      album_hash[product["id"]] = album
    end
    album_hash
  end

  # creates session to pass id to redirectToCheckout for Checkout functionality
  def create_stripe_session(products, cart, success_url, cancel_url)
    items=[]
    cart.each do |product_id, quantity|
        item = {}
        item["amount"] = products[product_id].price.to_i * 100
        item["currency"] = 'usd'
        item["name"] = products[product_id].name
        item["quantity"] = quantity
        items << (item)
      end
    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: items,
      success_url: success_url,
      cancel_url: cancel_url
  )
  end 

  #function to get 5 most recent charges and look to match to session on payment intent. NOTE: see README to see how I would use webhooks instead
  def get_charge_id(session_id) 
    if session_id != nil
      session = Stripe::Checkout::Session.retrieve(session_id)
      charge_list = Stripe::Charge.list({limit: 5})
      charge_list["data"].each do |charge|
        if charge["payment_intent"] == session["payment_intent"] && charge["status"] == "succeeded"
          return charge["id"]
        end
      end
    end
  end


def handle_charge_succeeded(charge)
  charge.id
end

end