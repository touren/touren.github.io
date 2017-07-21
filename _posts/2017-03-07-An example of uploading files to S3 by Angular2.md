---
layout: post
title: An example of uploading files to S3 by Angular2
tags: 
    - angular
---


S3 is a very popular cloud storage and using Amazon its official libraries to upload files to S3 is easy. But unfortunately Amazon doesn't have a library for Web Client. This is understanding because if you use Web Client to upload to S3, your secret access key will expose to every one who know how to read HTML. Therefore, Amazon's solution for web without its library is generating a **signature** on Web Server and put it in the form. Then after users select files, they can upload directly to S3 with the signature. See more Info in [Authenticating Requests: Browser-Based Uploads Using POST (AWS Signature Version 4)](http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-authentication-HTTPPOST.html). Anyway, if you awake that it is a risk of exposing your secret access key, but you still have to upload files on the client side because you don't have a server. Then, this is the article for you.

#[Live Demo in plnkr](http://embed.plnkr.co/MqLdcWF6W8NUwpuHWQZ0/)

#Steps
The most difficult thing to upload S3 is generating the signature. It is kind of like old-school technique OAuth-1, you have to hash strings over and over again.

## Step 1：Generating Policy String in Base64
```typescript
let date = this.generateTimestamp(); // returns yyyymmdd 
let datetime = date + 'T000000Z';

let credential = `${this.config.accessKey}/${date}/${this.config.region}/s3/aws4_request`;
// these are the least fields, you can put more, but it have to be matched in the form in step 4.
let policy = JSON.stringify({
    "expiration": (new Date(Date.now() + 100000)).toISOString(),
    "conditions": [
        {"bucket": this.config.bucket},
        ["starts-with", "$key", ""],
        {"acl": "public-read"},
        ["starts-with", "$Content-Type", ""],
        {"x-amz-credential": credential},
        {"x-amz-algorithm": "AWS4-HMAC-SHA256"},
        {"x-amz-date": datetime}
    ]
});

let policyBase64 = window.btoa(policy);
```

## Step 2：Generating Signature Key
you can use any implementation of HMAC-SHA256. In this sample, I use CryptoJS.
```typescript
let kDate = CryptoJS.HmacSHA256(datetime, "AWS4" + this.config.secretAccessKey);
let kRegion = CryptoJS.HmacSHA256(this.config.region, kDate);
let kService = CryptoJS.HmacSHA256("s3", kRegion);
let signatureKey = CryptoJS.HmacSHA256("aws4_request", kService);
```

## Step 3: Generating Signature based on Step 1 and Step 2.
```typescript
let signature = CryptoJS.HmacSHA256(policyBase64, signatureKey).toString(CryptoJS.enc.Hex);
```

Be careful, Policy is Base64, signature is Hexadecimal

## Step 4: Make FormData and upload
```typescript
upload(file: File): Promise<string> {
    let formData = new FormData();

    // if you have more fields, that you have to change policy in step 1
    formData.append('acl', "public-read");
    formData.append('Content-Type', file.type);
    formData.append('X-Amz-Date', datetime);
    formData.append('X-Amz-Algorithm', "AWS4-HMAC-SHA256");
    formData.append('X-Amz-Credential', credential);
    formData.append('X-Amz-Signature', signature);
    formData.append('Policy', policyBase64);
    formData.append('key', file.name);
    formData.append('file', file);

    // Upload a file
    return new Promise((resolve, reject) => {
        this.http.post("http://${this.config.bucket}.s3.amazonaws.com/", formData).subscribe(x => {
            console.log(x);
            resolve(x.headers.get("Location")); // return url 
        }, x => {
            console.error(x);
            reject();
        });
    });
}
```


That's it if you had settled your s3 bucket already. If you didn't, then there are more steps for you. 

## Step 5: Create Access Key for the bucket
Follow [Amazon's document](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) to create access key for the bucket.

## Step 6: Edit The Bucket's CORS
Because this is the client site script, there are stricter than other platforms. Your have to add [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS) settings in the bucket to tell browsers that uploading files from your domain to S3 is legal.

Go to Bucket > Properties > Permissions.
Click Edit CORS Configuration

![AWS](/assets/images/2017-03-07-1.png)

Add`<AllowedMethod>POST</AllowedMethod>` and `<ExposeHeader>Location</ExposeHeader>` like the below sample.
```
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <CORSRule>
        <AllowedOrigin>(your domain or *)</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>Authorization</AllowedHeader>
        <ExposeHeader>Location</ExposeHeader>
    </CORSRule>
</CORSConfiguration>
```

All done. you can put your bucket's config in [Live Demo](http://embed.plnkr.co/MqLdcWF6W8NUwpuHWQZ0/) to play around, but don't save or don't make the script public.