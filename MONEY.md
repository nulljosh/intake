# Intake Money

How Intake makes money. The fleet-wide ledger is `GTM.md` in the Code root.

## Price

Free. CSV export is $1 once, on the web.

## Rail

Stripe Checkout. `functions/api/stripe.js`, webhook writes `pro:<userId>`, `usePro` gates the Journal export.

## Why

Tracking is free so people build the habit. Export is what a serious user pays for.

## Next

Nothing until a store build is live again. Both platforms sit in the 4.3(a) wave.

## Change it

`STRIPE_PRICE_ID` secret on the Cloudflare Pages project, then redeploy.

Anyone who got Intake while it was free keeps it free. Only new customers pay.

*ASC 6785764864. Set 2026-09-20.*
