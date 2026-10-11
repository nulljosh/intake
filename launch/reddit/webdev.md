# r/webdev

Note: frame as "I built X to solve Y," this sub is fine with tech detail but not with a bare pitch. Check self-promo day/flair rules first. Public web app, no App Store link.

## Title
I built a dose tracker where the "active stack" is derived, never stored

## Body
Working on Healstack, a dose log and harm-reduction library. The interesting engineering problem was the "active stack": which substances are still active in your body right now. I could store that as a running list and expire entries with a background job, but instead I derive it on every read from dose timestamp plus known duration window. No job to keep correct, no drift, the state is just always right for the current moment.

Stack is React/Vite on the frontend, Supabase for auth and Postgres with row-level security scoped per user, deployed on Cloudflare Pages with Cloudflare Functions for the few server bits (Stripe webhook for the one-time CSV export unlock). Free to use, $1 one-time paid feature.

Happy to talk through the derived-state approach if anyone's solved something similar, or if there's an obvious hole in it I'm not seeing.

https://healstack.jaybulb.com
