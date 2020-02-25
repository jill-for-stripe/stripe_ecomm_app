# e-commerce web app: Abbey Road Vinyl
## Overview
Abbey Road Vinyl is an online store that sells classic rock albums on vinyl.
### Features
* Add items to the cart (click 'Add to Cart' multiple times to increase quantity)
* Remove items from the cart
* View cart and subtotal (for simplicity, this web app assumes no tax or shipping cost)
* Complete checkout on Stripe-hosted [Checkout](https://stripe.com/docs/payments/checkout) page

### How To Run
* Run on `localhost:9292` by calling `rackup` from the command line
* To run on a different port, call `rackup -p` with the correct port number. Make sure to edit `$success_url` and `$cancel_url` in app.rb if running on different port.

### Stripe APIs
The application uses the following APIs:

#### [Products](https://stripe.com/docs/api/service_products)
Data about the albums for sale was pushed to the Products API via POST request including name, image URL, type, and price (as an element of metadata). The Product data is pulled via GET request in a function called from the block of the index route in app.rb, and is used to display the available products on the index page.

#### [Sessions](https://stripe.com/docs/api/checkout/sessions)
When a user elects to check out, the block of the checkout route calls a function that creates a Session object via POST request with payment method type (card), line items, success URL (to route users if checkout is sucessful), and cancel URL (to route users if checkout is not completed). The Session object includes an `id` which is passed to checkout.erb to be used as a parameter to the `redirectToCheckout` JavaScript function which enables the Stripe-hosted Checkout functionality.

#### [PaymentIntents](https://stripe.com/docs/api/payment_intents)
Although my code doesn't call the PaymentIntent API directly, a PaymentIntent object is created during the Stripe Checkout process, and the `id` of this object is used to match other objects (see Charges below).

#### [Charges](https://stripe.com/docs/api/charges)
When the users checks out, a Charge object is created and the `id` of the object is displayed on the confirmation page. As the Session object and Charge object share a `payment_intent` for a given user session, the Charge object is accessed by pulling the most recent Charge objects via a GET request, and cross-referencing that the `payment_intent` from the Session object matches and that the status of the Charge is "succeeded" before capturing the `id` to be displayed.

**Note:** I would have preferred to have implemented the capture of the Charge ID using Stripe's webhooks, however I was unable to configure a webhook endpoint in the Dashboard, as the application runs locally. Had I been able to configure this, I would have created the webhook endpoint as a POST route in app.rb, configured it to handle `charge.succeeded` events (from the [Events](https://stripe.com/docs/api/events) API), and accessed the Charge ID from the `object` in the `data` field of the Event. The alternate implementation outlined above is sufficient for this exercise, but in a case where the application was not running locally and many users could be purchasing at the same time, the above implementation would not be optimal.

## Approaching the Problem
The first thing I did in approaching this project was to familiarize myself with Stripe's APIs and identify which ones would be applicable to this use case. I knew that Products, PaymentIntents, Charges, and Events would be involved. I considered the use of the Customers API, as this would be applicable in a more robust e-commerce app, but concluded that it would be unneccessary for this exercise.

Next, I considered the functionality that the application would need to have. As a baseline, it would need to display products and allow users to add products to a cart. The ability to add items to a cart implied the requirement to be able to remove items from a cart. Users would need to be able to navigate to the cart and to checkout, and the application would need to display how much they were going to be charged for a purchase, allow them to complete the purchase, and confirm to them that the purchase was successful. I reviewed Stripe's documentation on options for the checkout process, and determined that the Stripe-hosted [Checkout](https://stripe.com/docs/payments/checkout) feature would provide the most functional checkout page with the least amount of effort.

Once I had a framework for the project in mind, I set up my file structure for the Sinatra application. I created app.rb (server file) along with a Gemfile and a views folder containing four empty embedded Ruby (ERB) files for the index page, cart page, checkout, and confirmation page. In my server file, I created routes for each of the four views. As I worked through adding functionality to each page, I separated processes into functions to keep the blocks of the routes as simple and easy-to-follow as possible. I created a simple Class (`Album`) that held information about the product I was selling, and defined objects that were used in multiple areas throughout the program as global variables. Meanwhile, I kept the application running on `localhost` to test the functionality as each piece was added in.

## Why Ruby/Sinatra?
### Ruby
I hadn't written any code in Ruby in a couple of years, however I remembered it being easy to pick up and especially useful in creating web applications. I also enjoy the readability of Ruby and the ability to accomplish tasks using less code than many other languages. I decided to use this exercise as an opportunity to refresh my Ruby knowledge, and was pleased to find that I could to get back into the hang of it quickly.
### Sinatra
Once I had decided on Ruby, I was left to decide between the two Ruby frameworks that I'm familiar with: Rails and Sinatra. While Rails is a great and robust tool, Sinatra is much more lightweight and easy-to-follow in its simplicity. As the assignment was to create a simple program, Sinatra was the clear choice.

## Future Iterations
If I were to extend this application, the first priority would be to improve the styling and increase the number of products available. Beyond that, I would like to create a subscription option where the customer receives a new vinyl (or multiple) at a selected cadence. The customer would input details about their preferences in style, artists, etc. and a data science driven model would choose albums to send them. If the customer doesn't like the album they receive, they could send it back and be refunded. The customer would be prompted to rate each album they receive, and the model would use that data to improve the accuracy of its choices. Stripe's technology would be especially useful for easily maintaining and keeping track of the recurring payments associated with the subscripton and refunds for the rejected albums. Customers would be stored as objects in the Customers API, and info about albums they had received and associated ratings could be included in the metadata.
