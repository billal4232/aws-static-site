# terraform-cv-cloudfront

Static CV website hosted on private S3, delivered via CloudFront with a custom domain and HTTPS.

## Architecture
- S3 private bucket (public access blocked)
- CloudFront distribution with OAC authentication
- ACM certificate in us-east-1
- Route53 A record pointing cv.limonlab.online → CloudFront

## What I learned
- ACM certificates must be in us-east-1 for CloudFront regardless of your     main region
- Multi-provider Terraform config using aliases
- DNS validation flow for ACM via Route53 CNAME records
- Alias records vs standard A records in Route53

## Live site
https://cv.limonlab.online