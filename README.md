volcanic-apps
=============

A selection of in-service apps used on Volcanic's Recruitment Platform


EVERGRAD
===

Promotions app will simply expose a JSON endpoint with the active promotion (including price) for the user_type and dataset_id provided

The Payment app will query this endpoint to get the promotion price and code to prefill the payment form

The Payment app will then record what the payment was for (the Job) which can then be queried by the Evergrad Likes app when displaying an employer's Matches so that contact data can be hidden or revealed.