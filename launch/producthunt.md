# Product Hunt, Machaon

## Name
Machaon

## Tagline (60 max)
Know what you took, when, and what it's still doing

## Description (260 max)
A dose log, a harm reduction library, and a health dashboard. Log a dose in two taps, see what's still active in your body, and get warned before you combine two things that interact. 200 substances with hand-written notes. Your data stays on your device.

## Topics
- Health & Fitness
- Productivity
- Personal Health

## First comment (maker story)
I built Machaon because I take more than one supplement, and I could never actually picture how they overlapped in time. Two things taken on the same calendar day feel unrelated until you realize they were both active in your body at 3pm. That overlap is exactly where interactions live, and nobody keeps that timeline in their head.

Machaon logs a dose in two taps, then derives your "active stack" from duration windows instead of storing it separately, so it's always correct for right now without any background job. Log something and it checks against everything still active before the entry saves, not after, because a warning after you've already taken the dose can't change anything. Under that sits a library of 200 substances with harm-reduction notes I wrote by hand, plus daily check-ins, biometrics, a heatmap of patterns over time, and lab results in and out of range.

It's web, iOS, and macOS. Auth and storage run entirely on Supabase, row-level-security scoped per user, so I'm not holding your dose history on some server of mine. No analytics, no trackers.

Would love feedback on the interaction warnings especially. That's the part I care most about getting right.

Pricing: free app, $1 one-time CSV export on web.

## Links
- Web app: https://machaon.jaybulb.com
