# e-commerce web app: Abbey Road Vinyl
## Overview
Abbey Road Vinyl is an online store that sells classic rock albums on Vinyl.
### Features
* Add items to the cart (click 'Add to Cart' multiple times to increase quantity)
* Remove items from the cart
* View cart and subtotal (for simplicity, this web app assumes no tax or shipping cost)
* Complete checkout on Stripe-hosted [Checkout](https://stripe.com/docs/payments/checkout) page
### How Does It Work?

### Stripe APIs
The application uses the following APIs:

#### [Products](https://stripe.com/docs/api/service_products)
Data about the albums for sale was pushed to the Products API via POST request including name, image URL, type, and price (as an element of metadata). The Product data is pulled via GET request in a function called from the block of the index route in app.rb, and is used to display the available products on the index page.

#### [Sessions](https://stripe.com/docs/api/checkout/sessions)
When a user elects to check out, the block of the checkout route calls a function that creates a Session via POST request with payment method type (card), line items, success URL, and cancel URL. The Session object includes an `id` which is passed to checkout.erb to be used as a paramater to the `redirectToCheckout` JavaScript function which enables the Stripe-hosted Checkout functionality.

#### [Charges](https://stripe.com/docs/api/charges)
When the users checks out, a Charge object is created and the `id` of the object is displayed on the confirmation page. As the Session object and Charge object share a `payment_intent` for a given user session, the Charge object is accessed by pulling the most recent Charge objects via a GET request, and cross-referencing the that `payment_intent` from the Session object matches and that the status of the Charge is "succeeded" before capturing the `id` to be displayed.

**Note:** I would have preferred to have implemented the capture of the Charge ID using Stripe's webhooks, however I was unable to configure a webhook endpoint in the Dashboard, as the application runs locally. Had I been able to configure this, I would have created the webhook endpoint as a POST route in app.rb, configured it to handle `charge.succeeded` events (from the [Events](https://stripe.com/docs/api/events) API), and accessed the Charge ID from the `object` in the `data` field of the Event. The alternate implementation outlined above is sufficient for this exercise, but in a case where the application was not running locally and many users could be purchasing at the same time, this would not be optimal.
