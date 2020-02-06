# e-commerce web app: Abbey Road Vinyl
## Overview
Abbey Road Vinyl is an online store that sells classic rock albums on Vinyl.
### Features
* Add items to the cart (click 'Add to Cart' multiple times to increase quantity)
* Remove items from the cart
* View cart and subtotal (for simplicity, this web app assumes no tax or shipping cost)
* Complete checkout on Stripe-hosted [Checkout](https://stripe.com/docs/payments/checkout) page

### Stripe APIs
The application uses the following APIs:

#### [Products](https://stripe.com/docs/api/service_products)
Data about the albums for sale was pushed to the Products API via POST request including name, image URL, type, and price (as an element of metadata). The Product data is pulled via GET request in a function called from the block of the index route in app.rb, and is used to display the available products on the index page.

#### [Sessions](https://stripe.com/docs/api/checkout/sessions)
When a user elects to check out, the block of the checkout route calls a function that creates a Session via POST request with payment method type (card), line items, success URL, and cancel URL. The Session object includes an `id` which is passed to checkout.erb to be used as a paramater to the `redirectToCheckout` JavaScript function which enables the Stripe-hosted Checkout functionality.

#### [PaymentIntents](https://stripe.com/docs/api/payment_intents)
Although my code doesn't call the PaymentIntent API directly, a PaymentIntent object is created during the Stripe Checkout process, and the `id` of this object is used to match other objects (see Charges below).

#### [Charges](https://stripe.com/docs/api/charges)
When the users checks out, a Charge object is created and the `id` of the object is displayed on the confirmation page. As the Session object and Charge object share a `payment_intent` for a given user session, the Charge object is accessed by pulling the most recent Charge objects via a GET request, and cross-referencing the that `payment_intent` from the Session object matches and that the status of the Charge is "succeeded" before capturing the `id` to be displayed.

**Note:** I would have preferred to have implemented the capture of the Charge ID using Stripe's webhooks, however I was unable to configure a webhook endpoint in the Dashboard, as the application runs locally. Had I been able to configure this, I would have created the webhook endpoint as a POST route in app.rb, configured it to handle `charge.succeeded` events (from the [Events](https://stripe.com/docs/api/events) API), and accessed the Charge ID from the `object` in the `data` field of the Event. The alternate implementation outlined above is sufficient for this exercise, but in a case where the application was not running locally and many users could be purchasing at the same time, this would not be optimal.

## Approaching the Problem
The first thing I did in approaching this project was to familiarize myself with Stripe's APIs and identify which ones would be applicable to this use case. I knew that Products, PaymentIntents, Charges, and Events would be involved. I considered the use of the Customers API, as this would be applicable in a more robust e-commerce app, but concluded that it would be unneccessary for this exercise.

Next, I considered the functionality that the application would need to have. As a baseline, it would need to display products and allow users to add products to a cart. The ability to add items to a cart implied the requirement to be able to remove items from a cart. The application would need to show users how much they were going to be charged for a purchase, allow them to complete the purchase, and confirm to them that the purchase was successful. I reviewed Stripe's documentation on options for the checkout process, and determined that the Stripe-hosted [Checkout](https://stripe.com/docs/payments/checkout) feature would provide the most functional checkout page with the least amount of effort.

Once I had a framework for the project in mind, I set up my file structure for the Sinatra application. I created app.rb (server file) along with a Gemfile and a views folder containing four empty embedded Ruby (ERB) files for the index page, cart page, checkout, and confirmation page. In my server file, I created routes for each of the four views. As I worked through adding functionality to each page, I separated processes into functions to keep the blocks of the routes as simple as easy-to-follow as possible. I created a simple Class (`Album`) that held information about the product I was selling, and defined objects that were used in multiple areas throughout the program as global variables. Meanwhile, I kept the application running on `localhost:4567` to test the functionality as each piece was added in.
