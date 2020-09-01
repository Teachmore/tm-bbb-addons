# VdoCipher Ruby Uploader

Follow the below steps to upload a file to VdoCipher

## Clone the project

````bash
git clone git@github.com:harshalbhakta/VdoCipherRubyUploader.git
````

## Execute the PUT /videos request on Swagger or use CURL

### Swagger

https://dev.vdocipher.com/api/docs/swagger/

### CURL

````curl
curl -X PUT https://dev.vdocipher.com/api/videos?title=Hello -H "accept: application/json" -H "content-type: application/json" -H "Authorization: Apisecret XXXXXXX"
````

### Sample Response

You will get a response similar to the one shown below.

````json
{
  "clientPayload": {
    "policy": "",
    "key": "",
    "x-amz-signature": "",
    "x-amz-algorithm": "AWS4-HMAC-SHA256",
    "x-amz-date": "20200828T000000Z",
    "x-amz-credential": "",
    "uploadLink": "https://vdo-ap-southeast.s3-accelerate.amazonaws.com"
  },
  "videoId": ""
}
````

## Paste the response into the execute.rb file

````ruby
params = {
  "clientPayload": {
    "policy": "",
    "key": "",
    "x-amz-signature": "",
    "x-amz-algorithm": "AWS4-HMAC-SHA256",
    "x-amz-date": "20200828T000000Z",
    "x-amz-credential": "",
    "uploadLink": "https://vdo-ap-southeast.s3-accelerate.amazonaws.com"
  },
  "videoId": ""
}
````

## Run the execute.rb file to uplaod the file to VdoCipher

````bash
$ ruby execute.rb
````