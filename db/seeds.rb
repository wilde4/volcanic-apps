JobadderRequestBody.create(request_type: 'POST', endpoint: '/candidates', name: 'add_candidate',
                                  json: '{
"firstName": "string",
"lastName": "string",
"email": "string",
"phone": "string",
"mobile": "string",
"salutation": "string",
"statusId": 0,
"rating": "string",
"source": "string",
"seeking": "Yes",
"social": {
"property1": "string",
"property2": "string"
},
"address": {
"street": [
"string"
],
"city": "string",
"state": "string",
"postalCode": "string",
"countryCode": "string"
},
"skillTags": [
"string"
],
"employment": {
"current": {
"employer": "string",
"position": "string",
"workTypeId": 0,
"salary": {
"ratePer": "Hour",
"rate": 0,
"currency": "string"
}
},
"ideal": {
"position": "string",
"workTypeId": 0,
"salary": {
"ratePer": "Hour",
"rateLow": 0,
"rateHigh": 0,
"currency": "string"
},
"other": [
{
"workTypeId": 0,
"salary": {
"ratePer": "Hour",
"rateLow": 0,
"rateHigh": 0,
"currency": "string"
}
}
]
},
"history": [
{
"employer": "string",
"position": "string",
"start": "string",
"end": "string",
"description": "string"
}
]
},
"availability": {
"immediate": true,
"relative": {
"period": 0,
"unit": "Week"
},
"date": "2018-08-24"
},
"education": [
{
"institution": "string",
"course": "string",
"date": "string"
}
],
"custom": [
{
"fieldId": 0,
"value": { }
}
],
"recruiterUserId": [
0
]
}
')