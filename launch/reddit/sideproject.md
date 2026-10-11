# r/SideProject

Note: check current karma/account-age and flair requirements before posting. Public web app, no App Store link. Sub tends to reward a build story over a bare link, keep it personal.

## Title
I built a dose log that warns you before things overlap in your body

## Body
I take more than one supplement and could never actually picture how they overlapped in time. Two things taken on the same calendar day feel unrelated until you realize they were both active in your body at the same hour, and that's exactly where interactions matter.

So I built Healstack. Log a dose in two taps, it checks the new entry against everything still "active" (derived from duration windows, not stored separately) before the entry saves, not after. Underneath that sits a library of 200 substances with harm-reduction notes I wrote by hand, plus daily check-ins, a heatmap, and lab results in and out of range.

Stack: React/Vite frontend, Supabase for auth and storage with row-level security per user, deployed on Cloudflare Pages. Web, iOS, and macOS.

It's free to use. There's a $1 one-time CSV export on the web version if you want your data out.

Would genuinely like feedback on the interaction checker, that's the part I care about getting right.

https://healstack.jaybulb.com
